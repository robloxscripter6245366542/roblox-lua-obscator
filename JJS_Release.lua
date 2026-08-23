local _M1 = (function()
return function()
    local rs = game:GetService("ReplicatedStorage");
    local plrs = game:GetService("Players");
    local s = {
        rs = rs,
        plrs = plrs,
        runs = game:GetService("RunService"),
        uis = game:GetService("UserInputService"),
        debris = game:GetService("Debris"),
        stats = game:GetService("Stats"),
        kfp = game:GetService("KeyframeSequenceProvider"),
        http = game:GetService("HttpService"),
        vim = game:GetService("VirtualInputManager"),
        lp = plrs.LocalPlayer,
        cam = workspace.CurrentCamera,
        chars = workspace:WaitForChild("Characters"),
        animfld = rs:WaitForChild("Animations"),
    };
    local misc = s.animfld:WaitForChild("Misc");
    s.hits = misc:WaitForChild("Hits");
    s.movefld = misc:WaitForChild("Movement");
    s.knit = rs:WaitForChild("Knit"):WaitForChild("Knit"):WaitForChild("Services");
    s.dashrem = s.knit:WaitForChild("MovementService"):WaitForChild("RE"):WaitForChild("Dash");
    local bre = s.knit:WaitForChild("BlockService"):WaitForChild("RE");
    s.blockon, s.blockoff = bre:WaitForChild("Activated"), bre:WaitForChild("Deactivated");
    local dfre = s.knit:WaitForChild("DivergentFistService"):WaitForChild("RE");
    s.dfact, s.dfefx = dfre:WaitForChild("Activated"), dfre:FindFirstChild("Effects");
    s.movectrl = select(2, pcall(require, s.lp.PlayerScripts.Controllers.Character.MovementController));
    if type(s.movectrl) ~= "table" or not s.movectrl.Dash then s.movectrl = nil; end;
    s.pingitem = nil;
    pcall(function() s.pingitem = s.stats.Network.ServerStatsItem["Data Ping"]; end);
    return s;
end;

end)();
local _M2 = (function()
return function(ctx)
    local s = ctx.svc;
    local ut = {};
    local pool = {};

    function ut.weak(m)
        return setmetatable({}, { __mode = m or "k" });
    end;

    local nadd = 0;

    function ut.add(c)
        pool[#pool + 1] = c;
        nadd += 1;
        if nadd >= 256 then
            nadd = 0;
            ut.compact(pool);
        end;
        return c;
    end;

    function ut.compact(t)
        local j = 0;
        for i = 1, #t do
            local c = t[i];
            if typeof(c) ~= "RBXScriptConnection" or c.Connected then
                j += 1;
                t[j] = c;
            end;
        end;
        for i = j + 1, #t do t[i] = nil; end;
    end;

    function ut.drop(t)
        for _, c in t do pcall(function() c:Disconnect(); end); end;
        table.clear(t);
    end;

    function ut.dist2sq(a, b)
        local dx, dy, dz = a.X - b.X, a.Y - b.Y, a.Z - b.Z;
        return dx * dx + dy * dy + dz * dz;
    end;

    function ut.flat(v)
        local f = Vector3.new(v.X, 0, v.Z);
        return f.Magnitude < 0.01 and Vector3.new(0, 0, -1) or f.Unit;
    end;

    function ut.warn(tag, msg)
        warn("[jjs][" .. tag .. "] " .. tostring(msg));
    end;

    local charcache, charct = nil, 0;
    function ut.chars()
        local n = os.clock();
        if not charcache or n - charct > 0.1 then
            charcache = s.chars:GetChildren();
            charct = n;
        end;
        return charcache;
    end;

    local atc, att = ut.weak(), ut.weak();
    function ut.tracks(a)
        local n = os.clock();
        local lt = att[a];
        if lt and n - lt < 0.05 then
            local c = atc[a];
            if c then return c; end;
        end;
        local c = a:GetPlayingAnimationTracks();
        atc[a], att[a] = c, n;
        return c;
    end;

    function ut.hrp(c)
        return c and c:FindFirstChild("HumanoidRootPart");
    end;

    function ut.alive(c)
        local h = c and c:FindFirstChildOfClass("Humanoid");
        return h and h.Health > 0 and h or nil;
    end;

    function ut.unload()
        ut.drop(pool);
    end;

    return ut;
end;

end)();
local _M3 = (function()
return function(ctx)
    local cfg = { flags = nil, def = {} };

    function cfg.bind(f)
        cfg.flags = f;
    end;

    function cfg.get(k, d)
        local f = cfg.flags;
        local v = f and f[k];
        if v == nil then v = cfg.def[k]; end;
        if v == nil then return d; end;
        return v;
    end;

    function cfg.num(k, d)
        return tonumber(cfg.get(k, d)) or d;
    end;

    function cfg.on(k)
        return cfg.get(k, false) == true;
    end;

    ctx.opt = cfg.get;
    return cfg;
end;

end)();
local _M4 = (function()
return function(ctx)
    local env = getfenv();
    local caps = { missing = {}, lost = {} };

    local req = {
        LastM1 = { "hookmetamethod", "newcclosure", "getnamecallmethod", "checkcaller" },
        Bypass = { "hookmetamethod", "newcclosure", "getnamecallmethod", "checkcaller" },
        InfDash = { "debug.setupvalue" },
        Configs = { "writefile", "readfile", "isfolder", "makefolder", "listfiles", "delfile" },
        Sounds = { "getcustomasset", "listfiles", "isfile" },
    };
    caps.req = req;

    local names = {
        LastM1 = "Always Last M1",
        Bypass = "AC Bypass",
        InfDash = "Infinite Dash",
        Configs = "Config saving",
    };

    local cache = {};

    local function res(p)
        local d = p:find(".", 1, true);
        if not d then return env[p]; end;
        local t = env[p:sub(1, d - 1)];
        return type(t) == "table" and t[p:sub(d + 1)] or nil;
    end;
    caps.res = res;

    function caps.has(n)
        local c = cache[n];
        if c == nil then
            c = type(res(n)) == "function";
            cache[n] = c;
        end;
        return c;
    end;

    function caps.ok(k)
        local list = req[k];
        if not list then return true; end;
        for _, n in list do
            if not caps.has(n) then return false; end;
        end;
        return true;
    end;

    function caps.gap(k)
        local list = req[k];
        if not list then return nil; end;
        local bad = {};
        for _, n in list do
            if not caps.has(n) then bad[#bad + 1] = n; end;
        end;
        return #bad > 0 and table.concat(bad, ", ") or nil;
    end;

    for k in req do
        if not caps.ok(k) then
            caps.missing[#caps.missing + 1] = names[k] or k;
            caps.lost[#caps.lost + 1] = (names[k] or k) .. " (" .. caps.gap(k) .. ")";
        end;
    end;
    table.sort(caps.missing);
    table.sort(caps.lost);

    return caps;
end;

end)();
local _M5 = (function()
return function(ctx)
    local k = { id = "", code = "UNCHECKED", data = nil, msg = nil };
    local api = nil;

    local text = {
        UNCHECKED = "Checking",
        NO_SCRIPT_ID = "Not set",
        NO_KEY = "No key",
        FREE = "Free",
        KEY_VALID = "Valid",
        KEY_EXPIRED = "Expired",
        KEY_BANNED = "Blacklisted",
        KEY_HWID_LOCKED = "HWID locked",
        KEY_INCORRECT = "Not found",
        KEY_INVALID = "Bad format",
        SCRIPT_ID_INCORRECT = "Bad script id",
        SCRIPT_ID_INVALID = "Bad script id",
        INVALID_EXECUTOR = "Executor unsupported",
        SECURITY_ERROR = "Blocked",
        TIME_ERROR = "Clock error",
        UNKNOWN_ERROR = "Server error",
    };

    local function load()
        if api then return api; end;
        local ok, r = pcall(function()
            return loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))();
        end);
        api = ok and type(r) == "table" and r or nil;
        return api;
    end;

    local function gv(n)
        local ok, g = pcall(getgenv);
        if ok and type(g) == "table" then
            local v = rawget(g, n);
            if v ~= nil then return v; end;
        end;
        local v = rawget(_G, n);
        if v ~= nil then return v; end;
        local ok2, e = pcall(getfenv, 0);
        if ok2 and type(e) == "table" then
            local w = rawget(e, n);
            if w ~= nil then return w; end;
        end;
        return nil;
    end;

    function k.raw()
        local v = script_key or gv("script_key");
        return type(v) == "string" and v or nil;
    end;

    local L = ctx.lrm or {};

    local function pick(f, n)
        local v = L[f];
        if v == nil then v = gv(n); end;
        return v;
    end;

    local function lrm()
        local sl = pick("secs", "LRM_SecondsLeft");
        local pr = pick("prem", "LRM_IsUserPremium");
        if sl == nil and pr == nil then return false; end;
        k.src = "lrm";
        k.prem = pr ~= false;
        if pr == false then
            k.code, k.msg, k.data = "FREE", "No key", nil;
            return true;
        end;
        local n = tonumber(sl);
        k.code, k.msg = "KEY_VALID", "Authenticated";
        k.data = {
            auth_expire = (n and n ~= math.huge and n > 0) and (os.time() + math.floor(n)) or 0,
            total_executions = tonumber(pick("runs", "LRM_TotalExecutions")) or 0,
            note = pick("note", "LRM_UserNote"),
        };
        return true;
    end;

    function k.check()
        k.data, k.src = nil, nil;
        if lrm() then return k; end;
        local sk = k.raw();
        if k.id == "" then k.code = "NO_SCRIPT_ID"; return k; end;
        if not sk or #sk < 8 then k.code = "NO_KEY"; return k; end;
        local a = load();
        if not a then k.code = "UNKNOWN_ERROR"; return k; end;
        a.script_id = k.id;
        local ok, st = pcall(a.check_key, sk);
        if not ok or type(st) ~= "table" or not st.code then k.code = "UNKNOWN_ERROR"; return k; end;
        k.code, k.msg, k.data = st.code, st.message, st.data;
        return k;
    end;

    function k.ok()
        return k.code == "KEY_VALID";
    end;

    function k.label()
        return text[k.code] or k.code;
    end;

    function k.expiry()
        local d = k.data;
        if not d then return "-"; end;
        local e = tonumber(d.auth_expire) or 0;
        if e <= 0 then return "Lifetime"; end;
        local left = e - os.time();
        if left <= 0 then return "Expired"; end;
        if left >= 86400 then return math.floor(left / 86400) .. "d"; end;
        if left >= 3600 then return math.floor(left / 3600) .. "h"; end;
        return math.max(math.floor(left / 60), 1) .. "m";
    end;

    function k.runs()
        local d = k.data;
        return d and tostring(d.total_executions or 0) or "-";
    end;

    function k.note()
        local d = k.data;
        local n = d and d.note;
        return (type(n) == "string" and n ~= "") and n or "-";
    end;

    return k;
end;

end)();
local _M6 = (function()
return function(ctx)
    local s, ut = ctx.svc, ctx.ut;
    local animfld, hits = s.animfld, s.hits;
    local fl = {};

    local function enemy(studs, delay, closedelay, outdelay)
        local n = tonumber(studs) or 0;
        local d, cd, od;
        if type(delay) == "table" then
            d, cd, od = tonumber(delay.enter or delay.delay) or 0, tonumber(delay.close), tonumber(delay.out);
        else
            d, cd, od = tonumber(delay) or 0, tonumber(closedelay), tonumber(outdelay);
        end;
        return { mode = "enemy", r2 = n * n, d = d, cd = cd or d, od = od };
    end;
    fl.enemy = enemy;

    local denykw = {
        "block", "dash", "land", "ultimate", "hit", "down", "roll", "parkour", "idle", "spawn", "throwable", "nanami2", "arms", "ragdoll", "wakeup",
        "lapsebluemax", "reversalredmax", "hollowpurple", "infinitevoid",
        "manjikick", "flamearrow", "malevolentshrine", "rush", "counter",
        "domainwarn", "chant", "instincts", "teleport", "dodge", "taunt", "emote", "sprint", "parry", "flight", "recovery",
        "roughenergy", "idledeath",
        "divinedog", "maxelephant", "greatserpant", "mahoragause", "divinepummel", "groundpitch", "earthquake", "takedown", "adaptation", "worldslash",
        "bodyrepel", "selfperfection", "widestrike", "headsplitter",
        "supernova", "convergence", "wingking", "plasmawave",
        "brothers",
        "deadlysentence",
        "booston",
        "thisdesert", "overluck", "rhythm"
    };

    local overrides = {
        ["@chase"] = { counter = true, range = 50, ctrange = 35 },
        ["@down"] = { counter = true },

        ["Mahito.Variants.Armor.Melee1"] = { block = true },
        ["Mahito.Variants.Armor.Melee2"] = { block = true },
        ["Mahito.Variants.Armor.Melee3"] = { block = true },
        ["Mahito.Variants.Armor.Melee4"] = { block = true },
        ["Mahito.Variants.ChaseArmor"] = { block = true, multi = true, range = 20, punish = false },
        ["Mahito.Variants.MeleeSword.Melee1"] = { block = true },
        ["Mahito.Variants.MeleeSword.Melee2"] = { block = true },
        ["Mahito.Variants.MeleeSword.Melee3"] = { block = true },
        ["Mahito.Variants.MeleeSword.Melee4"] = { block = true },
        ["Mahito.Variants.ChaseSword"] = { block = true, range = 65, punish = false },
        ["Mahito.Variants.MeleeClub.Melee1"] = { block = true },
        ["Mahito.Variants.MeleeClub.Melee2"] = { block = true },
        ["Mahito.Variants.MeleeClub.Melee3"] = { block = false, counter = true },
        ["Mahito.Variants.MeleeClub.Melee4"] = { block = false, counter = true },
        ["Mahito.Variants.ChaseClub"] = { block = false, counter = true, ctrange = 45, ctwait = 0.2, punish = false },
        ["Mahito.Melee.Melee1"] = { block = true },
        ["Mahito.Melee.Melee2"] = { block = true },
        ["Mahito.Melee.Melee3"] = { block = true },
        ["Mahito.Melee.Melee4"] = { block = true },
        ["@stockpile"] = { counter = true, multi = true },
        ["@soulfire"] = { block = true, counter = true, multi = true, range = 100 },
        ["@idletransfig"] = { block = false, counter = true, ctrange = 100, ctwait = enemy(25) },
        ["@spikewrath"] = { block = true, multi = true, counter = true, ctrange = 100, ctwait = enemy(55, 0.3, 0.2) },
        ["@heartpiercer"] = { counter = true, ctrange = 35, ctwait = enemy(15) },
        ["@drillsplit"] = { block = false, counter = true, ctrange = 40, ctwait = enemy(10, 0.3) },
        ["@forcegrab"] = { block = false, counter = true, ctrange = 100, ctwait = enemy(40, 0.1) },
        ["@ultimate2"] = { block = false, counter = true, ctrange = 100, ctwait = enemy(15) },
        ["@faceblitz"] = { block = false, counter = true, ctrange = 100, ctwait = enemy(55, { enter = 0.3, close = 0.2, out = 0.15 }) },
        ["@focusstrike"] = { block = true, counter = true },
        ["@crushingrushdown"] = { multi = true, block = true, counter = true, ctrange = 100 },

        ["@rapidpunches"] = { block = false, counter = true, ctrange = 20, ctwait = 0.1 },
        ["@lapseblue"] = { counter = true, ctrange = 20, ctwait = 0.1 },
        ["@reversalred"] = { counter = true, ctrange = 20, ctwait = 0.1 },

        ["@dismantle"] = { counter = true, multi = true, holdextra = 0.1 },
        ["@cleave"] = { counter = true },

        ["@reserveballs"] = { block = true, counter = true, multi = true, ctrange = 30, ctwait = 0.1, holdondoors = true, doorrange = 5, doortimeout = 6 },
        ["@luckyvolley"] = { block = false, counter = true, multi = true, range = 15 },
        ["@luckyrushdown"] = { block = false, counter = true, range = 20 },
        ["@overwhelmingluck"] = { block = false, counter = true },
        ["@energysurge"] = { block = false, counter = true, range = 20 },

        ["@rabbitescape"] = { multi = true, holdextra = 1, range = 50 },
        ["@nue"] = { block = false, counter = true, ctrange = 35 },
        ["@toad"] = { counter = true, ctrange = 75, ctwait = 0.2 },
        ["@shadowswarm"] = { block = false, counter = true, ctrange = 35, ctwait = enemy(10) },

        ["@piercingblood"] = { counter = true, ctrange = 35, ctwait = 0.25 },
        ["@redscale"] = { counter = true, ctrange = 25 },
        ["@bloodedge"] = { multi = true },
        ["@slicingexorcism"] = { block = false, counter = true, ctrange = 40, ctwait = 0.15 },

        ["@swiftkick"] = { block = true, counter = true, ctrange = 50, ctwait = enemy(55, { enter = 0.01, close = 0.2 }) },
        ["@bruteforce"] = { block = false, counter = true, ctwait = 0.15 },
        ["@pebblethrow"] = { block = true, multi = true, counter = true, ctwait = 0.15, range = 85 },
        ["@pebblethrowhit"] = { block = true, multi = true, counter = true, ctwait = 0.15, range = 85 },
        ["@elbowdrop"] = { block = false, counter = true, ctwait = 0.2 },
        ["@idoldebut"] = { block = false, counter = true, ctwait = 0.1 },
        ["@climaxjump"] = { block = false, counter = true, ctrange = 100, ctwait = enemy(30, { enter = 0, close = 0.5, out = 0.75 }) },
        ["@dreams"] = { block = false, counter = true, ctrange = 100, ctwait = enemy(20, { enter = 0, close = 0.2, out = 0.35 }) },

        ["@extendswing"] = { block = true, counter = true, multi = true, punish = true },
        ["@justiceserved"] = { block = false, counter = true, ctwait = 0.15 },
        ["Hiromi.Melee.Melee2"] = { block = true, counter = true, multi = true, punish = true },
        ["@judgereach2"] = { counter = true, ctrange = 35, ctwait = 0.15, block = true, range = 35 },
        ["@pressingcharges"] = { counter = true, ctrange = 30, punish = false, multi = true },
        ["@gavelthrow"] = { block = false, counter = true, ctrange = 30, ctwait = 0.1 },
        ["@execution"] = { block = false, counter = true, ctwait = 0.7, ctrange = 50 },
        ["@finaljudgement"] = { block = false, counter = true, ctrange = 100, ctwait = 1.25 },
        ["@verdict"] = { block = false, counter = true },
        ["@triplesentence"] = { block = true },

        ["@resoluteslash"] = { block = false, counter = true, ctwait = 0.3, ctrange = 30 },
        ["@sheath"] = { block = false, counter = false, punish = false },
        ["@outburst"] = { block = true, counter = true, ctwait = 0.15, multi = true },
        ["@secondwind"] = { block = true, counter = true, ctrange = 22, ctwait = 0.2 },
        ["@energyripple"] = { block = false, counter = false },

        ["@booston"] = { counter = true, ctwait = 0.1 },
        ["@ultracannon"] = { block = true, counter = false, range = 75 },
        ["@heatemission"] = { block = true, counter = false, range = 25 },
        ["@miraclecannon"] = { block = false, counter = false },
        ["@jumpcrouch"] = { block = false, counter = false },
        ["@pigeonviola"] = { block = false, counter = false },
        ["@dropkick"] = { block = false, counter = false },
        ["@absolutedestruction"] = { block = false, counter = false },
        ["@gunshot"] = { block = false, counter = false },
        ["@boostonstart"] = { block = true, counter = true, range = 20, ctrange = 25, ctwait = 0.1 },

        ["@bleedout"] = { block = false, counter = true, ctwait = 0.2 },
        ["@decisivestrike"] = { block = true, counter = true, decisive = true },
        ["Haruta.Taunt1"] = { block = false, counter = false, multi = false, punish = false },
        ["Haruta.Taunt2"] = { block = false, counter = false, multi = false, punish = false },
        ["Haruta.Taunt3"] = { block = false, counter = false, multi = false, punish = false },
        ["Haruta.Taunt4"] = { block = false, counter = false, multi = false, punish = false },
        ["MeiMei.Murmurate"] = { block = true, counter = true, multi = true, punish = false, range = 30, ctrange = 30, ctwait = 0.2 },
        ["MeiMei.BirdHold"] = { block = false, counter = false, multi = false, punish = false },
        ["MeiMei.BirdCall"] = { block = false, counter = false, multi = false, punish = false },
        ["MeiMei.Circling"] = { block = true, counter = true, multi = true, punish = false, range = 24, ctrange = 24, ctwait = 0.2 },
        ["Kurourushi.FesteringStrikes"] = { block = true, counter = true, multi = true, punish = false, range = 26, ctrange = 17, ctwait = 0.2 },
        ["Kurourushi.Detach"] = { block = true, counter = true, multi = true, punish = false, range = 81, ctrange = 81, holdextra = 0.3, ctwait = 0.2 },
        ["Kurourushi.Chokehold"] = { block = true, counter = true, multi = false, punish = true, range = 11, ctrange = 11, ctwait = 0 },
        ["Hanami.SurgingThorns"] = { block = true, counter = true, multi = true, punish = false, range = 25, ctrange = 25, ctwait = 0.1 },
        ["Hanami.FlowerField"] = { block = false, counter = false, multi = false, punish = false },
        ["Hanami.RootSwarm"] = { block = false, counter = false, multi = false, punish = false },
        ["Hakari.Counter"] = { block = false, counter = false, multi = false, punish = false },
        ["Yuki.RisingStar"] = { block = true, counter = true, multi = true, punish = false, range = 13, ctrange = 13, ctwait = 0.1 },
        ["Yuki.MassBreaker"] = { block = false, counter = true, multi = false, punish = false, ctrange = 44, ctwait = 0.3 },
        ["Yuki.GarudaStab"] = { block = false, counter = true, multi = false, punish = false, ctrange = 13, ctwait = 0.2 },
        ["Yuki.GarudaRebound"] = { block = true, counter = true, multi = true, punish = false, range = 65, ctrange = 65, holdextra = 0.4, ctwait = 0.3 },
        ["Nanami.Stabilize"] = { block = true, counter = true, multi = false, punish = true, range = 12, ctrange = 12, ctwait = 0.2 },
        ["Nanami.RatioBreaker.RatioBreak1"] = { block = false, counter = true, multi = false, punish = false, ctrange = 15, ctwait = 0 },
        ["Nanami.RatioBreaker.RatioBreak2"] = { block = false, counter = true, multi = false, punish = false, ctrange = 15, ctwait = 0 },
        ["Nanami.RatioBreaker.RatioBreak3"] = { block = false, counter = true, multi = false, punish = false, ctrange = 15, ctwait = 0 },
        ["Nanami.RatioBreaker.RatioBreak4"] = { block = false, counter = true, multi = false, punish = false, ctrange = 15, ctwait = 0 },
        ["Nanami.Interrogate"] = { block = false, counter = true, multi = false, punish = false, ctrange = 23, ctwait = 0.2 },
        ["Nanami.BluntCut"] = { block = true, counter = true, multi = false, punish = false, range = 50, ctrange = 50, ctwait = 0.6 },
        ["Nanami.CleavingWhirlwind"] = { block = true, counter = true, multi = false, punish = true, range = 34, ctrange = 34, ctwait = 0.2 },
        ["Nanami.SeveranceKick"] = { block = true, counter = true, multi = false, punish = false, range = 15, ctrange = 15, ctwait = 0.2 },
        ["Naoya.CursoryImpact"] = { block = false, counter = true, multi = false, punish = false, ctrange = 39, ctwait = 0.2 },
        ["Naoya.ProjectionBreaker"] = { block = true, counter = true, multi = false, punish = true, range = 30, ctrange = 30, ctwait = 0.2 },
        ["Naoya.FlashFreezing"] = { block = false, counter = false, multi = false, punish = false },
        ["Naoya.TopSpeed"] = { block = false, counter = true, multi = false, punish = false, ctrange = 80, ctwait = enemy(20) },
        ["Megumi.GreatSerpent"] = { block = false, counter = true, multi = false, punish = false, ctrange = 80, ctwait = enemy(20) },
        ["Megumi.Mahoraga.DivinePummel"] = { block = false, counter = true, multi = false, punish = false, ctrange = 12, ctwait = 0.2 },
        ["Megumi.Mahoraga.Takedown"] = { block = false, counter = true, multi = false, punish = false, ctrange = 72, ctwait = 0.2 },
        ["Megumi.Mahoraga.Earthquake"] = { block = false, counter = true, multi = false, punish = false, ctrange = 35, ctwait = 0.32 },
        ["Hakari.ShutterDoors"] = { block = true, counter = true, multi = false, punish = false, range = 28, ctrange = 28, ctwait = 0.2 },
        ["Hakari.RoughEnergy"] = { block = true, counter = true, multi = false, punish = false, range = 21, ctrange = 21, ctwait = 0.2 },
        ["Hakari.FeverBreaker"] = { block = true, counter = true, multi = false, punish = true, range = 13, ctrange = 13 },
        ["Itadori.CursedStrike"] = { block = true, counter = true, multi = false, punish = true, range = 33, ctrange = 33, ctwait = 0.38 },
        ["Itadori.Variants.DivergentFist1"] = { block = false, counter = true, multi = false, punish = true, range = 15, ctrange = 20, ctwait = 0 },
        ["Itadori.Variants.DivergentFist2"] = { block = false, counter = true, multi = false, punish = false, range = 15, ctrange = 20, ctwait = 0 },
        ["Itadori.Variants.DivergentFist3"] = { block = false, counter = true, multi = false, punish = false, range = 15, ctrange = 20, ctwait = 0 },
        ["Itadori.Variants.DivergentFist4"] = { block = false, counter = true, multi = false, punish = false, range = 15, ctrange = 20, ctwait = 0 },
        ["Itadori.CrushingBlow"] = { block = false, counter = true, multi = false, punish = false, ctrange = 13, ctwait = 0 },
        ["Itadori.Rush"] = { block = false, counter = true, multi = false, punish = false, ctrange = 52, ctwait = 0.3 },
        ["Ryu.Recovery"] = { block = false, counter = false, multi = false, punish = false },
        ["Ryu.Recovery2"] = { block = false, counter = false, multi = false, punish = false },
        ["Ryu.Recovery3"] = { block = false, counter = false, multi = false, punish = false },
        ["Ryu.GraniteBlast"] = { block = true, counter = true, multi = false, punish = false, range = 75, ctrange = 75, ctwait = 0.2 },
        ["Ryu.Unsatisfied"] = { block = true, counter = true, multi = true, punish = false, range = 32, ctrange = 11, ctwait = 0.1 },
        ["Ryu.Appetizer"] = { block = true, counter = true, multi = true, punish = false, range = 78, ctrange = 73, ctwait = 0.2 },
        ["Ryu.WhatAreYouAfter"] = { block = false, counter = true, multi = false, punish = false, ctrange = 23, ctwait = 0.2 },
        ["Ryu.WerentInvited"] = { block = false, counter = false, multi = false, punish = false },
        ["Ryu.HadNoIdea"] = { block = false, counter = true, multi = false, punish = false, ctrange = 25, ctwait = 0.3 },
        ["Ryu.SecondHelping"] = { block = false, counter = true, multi = false, punish = false, ctrange = 71, ctwait = 0 },
        ["Locust.Flight"] = { block = false, counter = false, multi = false, punish = false },
        ["Locust.FourArmed"] = { block = true, counter = true, multi = true, punish = false, range = 25, ctrange = 14, ctwait = 0.2 },
        ["Locust.BlackMucus"] = { block = false, counter = true, multi = false, punish = false, ctrange = 60, ctwait = 0.4 },
        ["Locust.BugFlight"] = { block = true, counter = true, multi = false, punish = false, range = 13, ctrange = 13, ctwait = 0 },
        ["Charles.Mark"] = { block = false, counter = false, multi = false, punish = false },
        ["Charles.Despair"] = { block = true, counter = true, multi = true, punish = false, range = 16, ctrange = 16, ctwait = 0.1 },
        ["Charles.ShutUp"] = { block = true, counter = true, multi = false, punish = false, range = 11, ctrange = 11, ctwait = 0 },
        ["Charles.Sacrilegious"] = { block = false, counter = true, multi = false, punish = false, ctrange = 33, ctwait = 0.1 },
        ["Haruta.Backstab"] = { block = false, counter = true, multi = false, punish = false, ctrange = 13, ctwait = 0 },
        ["Haruta.Ambush"] = { block = false, counter = true, multi = false, punish = false, ctrange = 16, ctwait = 0.2 },
        ["Haruta.Trip"] = { block = true, counter = true, multi = false, punish = false, range = 11, ctrange = 11, ctwait = 0 },
        ["Todo.Clap.Clap1"] = { block = true, counter = false, multi = false, punish = false, range = 61 },
    };

    local counterall = {
        { svc = "ManjiKickService", ev = "Activated", mv = "Manji Kick" };
        { svc = "HeadSplitterService", ev = "Activated", mv = "Head Splitter" };
        { svc = "EyeCatchService", ev = "Activated", mv = "Eye Catching" };
        { svc = "AdaptationService", ev = "Activated", mv = "Adaptation" };
        { svc = "SupernovaService", ev = "Activated", mv = "Supernova", gated = true };
    };

    local bfcfg = {
        focusstrike = { mv = "Focus Strike", svc = "FocusStrikeService", ev = "Activated", d = 0.33 };
        ultimate2 = { svc = "MahitoService", ev = "Ultimate", d = 0, noarg = true, require = "mahito" };
    };

    local blockids, punishids, adaptids, animflags, hitids, bfnames, idnames = {}, {}, {}, {}, {}, {}, {};
    local selfblkids, blkhitids = {}, {};
    local blockcnt, punishcnt = {}, {};
    local wasblk, waspun = ut.weak(), ut.weak();
    local pathrefs, pathids, idpaths, allpaths, upids, melids = {}, {}, {}, {}, {}, {};
    local pathcache, nidcache, chaincache = ut.weak(), {}, {};

    fl.denykw, fl.overrides, fl.counterall, fl.bfcfg = denykw, overrides, counterall, bfcfg;
    fl.blockids, fl.punishids, fl.adaptids = blockids, punishids, adaptids;
    fl.animflags, fl.hitids, fl.bfnames, fl.idnames = animflags, hitids, bfnames, idnames;
    fl.selfblkids = selfblkids;
    fl.idpaths, fl.pathids, fl.allpaths, fl.upids, fl.melids = idpaths, pathids, allpaths, upids, melids;
    fl.dirty = false;

    local function relpath(inst)
        if not inst then return nil; end;
        local p = inst.Parent;
        if not p then return nil; end;
        if p == animfld then
            local n = inst.Name;
            pathcache[inst] = n;
            return n;
        end;
        local pp = pathcache[p];
        if pp == nil then pp = relpath(p) or false; end;
        if pp == false then return nil; end;
        local n = pp .. "." .. inst.Name;
        pathcache[inst] = n;
        return n;
    end;

    local function normid(id)
        local c = nidcache[id];
        if c then return c; end;
        local s2 = tostring(id or "");
        local r = s2:match("%d+") or s2;
        nidcache[id] = r;
        return r;
    end;

    local function getov(path, d)
        return (path and overrides[path]) or overrides["@" .. d.Name:lower()] or overrides[d.Name] or overrides[d.Name:lower()];
    end;

    fl.relpath, fl.normid, fl.getov = relpath, normid, getov;

    function fl.apath(anim, id)
        local rp = relpath(anim);
        if rp then return "game:GetService(\"ReplicatedStorage\").Animations." .. rp; end;
        local set = idpaths[normid(id or (anim and anim.AnimationId))];
        if set then for p in set do return "game:GetService(\"ReplicatedStorage\").Animations." .. p; end; end;
        return anim and anim:GetFullName() or tostring(id);
    end;

    local function applyflags(d, nid, path)
        local ov = getov(path, d);
        local blk;
        if ov and ov.block ~= nil then
            blk = ov.block;
        else
            local chain = d.Name:lower();
            if path and path ~= "" then chain = chain .. "/" .. path:lower(); end;
            local cached = chaincache[chain];
            if cached ~= nil then
                blk = cached;
            else
                blk = true;
                for _, kw in denykw do
                    if chain:find(kw, 1, true) then blk = false; break; end;
                end;
                chaincache[chain] = blk;
            end;
        end;
        local pun = blk and not (ov and ov.punish == false);
        local pb = wasblk[d];
        if blk and not pb then
            blockcnt[nid] = (blockcnt[nid] or 0) + 1;
            wasblk[d] = true;
        elseif not blk and pb then
            local c = (blockcnt[nid] or 1) - 1;
            blockcnt[nid] = c > 0 and c or nil;
            wasblk[d] = nil;
        end;
        local pp = waspun[d];
        if pun and not pp then
            punishcnt[nid] = (punishcnt[nid] or 0) + 1;
            waspun[d] = true;
        elseif not pun and pp then
            local c = (punishcnt[nid] or 1) - 1;
            punishcnt[nid] = c > 0 and c or nil;
            waspun[d] = nil;
        end;
        blockids[nid] = blockcnt[nid] and true or nil;
        punishids[nid] = punishcnt[nid] and true or nil;
        adaptids[nid] = (ov and ov.adapt) or nil;
        animflags[nid] = ov;
        if d:IsDescendantOf(hits) then
            hitids[nid] = true;
            local pn = d.Parent and d.Parent.Name or "";
            if pn == "Block" or pn:find("Deflect") then blkhitids[nid] = true; end;
        end;
        local lname = d.Name:lower();
        idnames[nid] = lname;
        local bf = bfcfg[lname];
        if not bf then
            for k, v in bfcfg do
                if lname:sub(1, #k) == k then bf = v; break; end;
            end;
        end;
        bfnames[nid] = (bf and (not bf.require or ((path or ""):lower():find(bf.require, 1, true)))) and bf or nil;
    end;
    fl.applyflags = applyflags;

    local function procanim(d)
        if not d:IsA("Animation") then return; end;
        local id = d.AnimationId;
        if not id or id == "" then return; end;
        local nid, path = normid(id), relpath(d);
        if d.Name == "Up" then upids[nid] = true; end;
        local par = d.Parent;
        if par and par.Name:sub(1, 5) == "Melee" and d.Name ~= "Chase" then melids[nid] = true; end;
        if path then
            if path:sub(1, 11) == "Misc.Block." and d.Name:lower() ~= "nanami2" then selfblkids[nid] = true; end;
            pathrefs[path] = (pathrefs[path] or 0) + 1;
            if not pathids[path] then
                pathids[path] = nid;
                allpaths[#allpaths + 1] = path;
                fl.dirty = true;
            end;
            local set = idpaths[nid];
            if not set then set = {}; idpaths[nid] = set; end;
            set[path] = true;
        end;
        applyflags(d, nid, path);
    end;
    fl.procanim = procanim;

    local function remanim(d)
        if not d:IsA("Animation") then return; end;
        local id = d.AnimationId;
        if not id or id == "" then return; end;
        local nid = normid(id);
        if wasblk[d] then
            local c = (blockcnt[nid] or 1) - 1;
            blockcnt[nid] = c > 0 and c or nil;
            wasblk[d] = nil;
        end;
        if waspun[d] then
            local c = (punishcnt[nid] or 1) - 1;
            punishcnt[nid] = c > 0 and c or nil;
            waspun[d] = nil;
        end;
        blockids[nid] = blockcnt[nid] and true or nil;
        punishids[nid] = punishcnt[nid] and true or nil;
        local path = relpath(d);
        if not path then return; end;
        local n = (pathrefs[path] or 1) - 1;
        if n > 0 then pathrefs[path] = n; return; end;
        pathrefs[path], pathids[path] = nil, nil;
        for i = #allpaths, 1, -1 do
            if allpaths[i] == path then table.remove(allpaths, i); break; end;
        end;
        fl.dirty = true;
        if not blockcnt[nid] then
            hitids[nid], animflags[nid], bfnames[nid], adaptids[nid] = nil, nil, nil, nil;
            blkhitids[nid] = nil;
        end;
        local set = idpaths[nid];
        if set then
            set[path] = nil;
            if not next(set) then idpaths[nid] = nil; end;
        end;
    end;
    fl.remanim = remanim;

    function fl.reapply()
        for _, d in animfld:GetDescendants() do
            if d:IsA("Animation") then
                local id = d.AnimationId;
                if id and id ~= "" then applyflags(d, normid(id), relpath(d)); end;
            end;
        end;
    end;

    function fl.flags(id)
        return animflags[normid(id)];
    end;

    function fl.name(id)
        return idnames[normid(id)];
    end;

    function fl.blockable(id)
        return blockids[normid(id)] == true;
    end;

    function fl.selfblock(id)
        return selfblkids[normid(id)] == true;
    end;

    function fl.punishable(id)
        return punishids[normid(id)] == true;
    end;

    function fl.blockhit(id)
        return blkhitids[normid(id)] == true;
    end;

    function fl.rangesq(af, def)
        local r = math.max((af and af.range) or def, def);
        return r * r;
    end;

    function fl.ctrangesq(af, def)
        local r = (af and af.ctrange) or def;
        return r * r;
    end;

    function fl.ctwait(af, lhrp, thrp)
        local w = af and af.ctwait;
        if type(w) ~= "table" then
            local d = tonumber(w) or 0;
            if d > 0 then task.wait(d); end;
            return true;
        end;
        if ut.dist2sq(lhrp.Position, thrp.Position) <= w.r2 then
            if w.cd > 0 then task.wait(w.cd); end;
            return true;
        end;
        local t0 = os.clock();
        local lim = w.od;
        while os.clock() - t0 < 1.5 do
            if not (lhrp.Parent and thrp.Parent) then return false; end;
            if ut.dist2sq(lhrp.Position, thrp.Position) <= w.r2 then
                if w.d > 0 then task.wait(w.d); end;
                return true;
            end;
            if lim and os.clock() - t0 >= lim then return true; end;
            task.wait(0.05);
        end;
        return lim ~= nil;
    end;

    fl.ready = false;
    task.spawn(function()
        local ds = animfld:GetDescendants();
        for i = 1, #ds do
            procanim(ds[i]);
            if i % 100 == 0 then task.wait(); end;
        end;
        fl.ready = true;
        if fl.onready then pcall(fl.onready); end;
    end);

    ut.add(animfld.DescendantAdded:Connect(procanim));
    ut.add(animfld.DescendantRemoving:Connect(remanim));

    function fl.status()
        return { ready = fl.ready, paths = #allpaths, blocked = blockids, overrides = overrides };
    end;

    return fl;
end;

end)();
local _M7 = (function()
return function(ctx)
    local ut = ctx.ut;
    local dh = { hold = false, track = nil, tok = 0 };

    function dh.near(pos, rsq)
        local fx = workspace:FindFirstChild("Effects");
        if not fx then return false; end;
        for _, c in fx:GetChildren() do
            if c.Name == "Doors" then
                local p;
                if c:IsA("BasePart") then
                    p = c.Position;
                elseif c:IsA("Model") then
                    local ok, cf = pcall(c.GetPivot, c);
                    if ok and cf then p = cf.Position; end;
                else
                    local pp = c:FindFirstChildWhichIsA("BasePart", true);
                    if pp then p = pp.Position; end;
                end;
                if p and ut.dist2sq(pos, p) <= rsq then return true; end;
            end;
        end;
        return false;
    end;

    function dh.arm(af, pos, track)
        if not (af and af.holdondoors and track) then return false; end;
        local dr = af.doorrange or 5;
        if not dh.near(pos, dr * dr) then return false; end;
        dh.hold, dh.track = true, track;
        dh.tok += 1;
        local tok = dh.tok;
        local to = af.doortimeout or 6;
        track.Stopped:Once(function()
            if dh.tok ~= tok then return; end;
            task.delay(to, function()
                if dh.tok ~= tok then return; end;
                dh.hold, dh.track = false, nil;
            end);
        end);
        return true;
    end;

    function dh.owns(track)
        return dh.hold and dh.track == track;
    end;

    function dh.release()
        dh.tok += 1;
        dh.hold, dh.track = false, nil;
    end;

    return dh;
end;

end)();
local _M8 = (function()
return function(ctx)
    local s, ut = ctx.svc, ctx.ut;
    local ac = {};
    local dirs = {
        Back = Vector3.new(0, 0, 1),
        Front = Vector3.new(0, 0, -1),
        Left = Vector3.new(-1, 0, 0),
        Right = Vector3.new(1, 0, 0),
    };

    function ac.firesvc(svcname, remote, ...)
        local svc = s.knit:FindFirstChild(svcname);
        local re = svc and svc:FindFirstChild("RE");
        local rem = re and re:FindFirstChild(remote);
        if not rem then return false; end;
        rem:FireServer(...);
        return true;
    end;

    function ac.ability(abil, svcname)
        local ch = s.lp.Character;
        local ms = ch and ch:FindFirstChild("Moveset");
        local tool = ms and ms:FindFirstChild(abil);
        if not tool then return; end;
        ac.firesvc(svcname, "Activated", tool);
    end;

    function ac.blackflash()
        ac.ability("Divergent Fist", "DivergentFistService");
    end;

    function ac.moveset()
        local ch = s.lp.Character;
        return ch and ch:GetAttribute("Moveset");
    end;

    function ac.dashanim(ch, dir, prio)
        local hum = ch and ch:FindFirstChildOfClass("Humanoid");
        local an = hum and s.movefld:FindFirstChild("Dash" .. dir);
        if not an then return nil; end;
        local ok, tr = pcall(hum.LoadAnimation, hum, an);
        if not ok then return nil; end;
        tr.Priority = prio or Enum.AnimationPriority.Action4;
        tr:Play(nil, nil, dir == "Back" and 0.8 or 1.8);
        return tr;
    end;

    function ac.m1(mode, tgt)
        local mv = ac.moveset();
        if not mv then return false; end;
        return ac.firesvc(mv .. "Service", "Activated", mode, tgt);
    end;

    function ac.dashlocal(ch, dir)
        local c = s.movectrl;
        if not (c and c.Dash) then return false; end;
        local ok = pcall(c.Dash, c, s.lp, ch, dir);
        if not ok then
            pcall(function()
                local kc = require(s.rs.Knit.Knit).GetController("MovementController");
                if kc and kc ~= c then s.movectrl = kc; c = kc; end;
            end);
            ok = pcall(c.Dash, c, s.lp, ch, dir);
        end;
        return ok;
    end;

    function ac.dashforce(ch, dir)
        if not ch then return false; end;
        local torso = ch:FindFirstChild("Torso");
        local hrp = ut.hrp(ch);
        if not (torso and hrp) then return false; end;
        for _, i in torso:GetChildren() do
            if i.Name == "MovementForce" then pcall(i.Destroy, i); end;
        end;
        local old = hrp:FindFirstChild("MovementForce");
        if old then pcall(old.Destroy, old); end;
        local hum = ch:FindFirstChildOfClass("Humanoid");
        if hum then
            local an = s.movefld:FindFirstChild("Dash" .. dir);
            if an then
                pcall(function()
                    local tr = hum:LoadAnimation(an);
                    tr.Priority = Enum.AnimationPriority.Movement;
                    tr:Play(nil, nil, dir == "Back" and 0.8 or 1.8);
                end);
            end;
        end;
        local info = ch:FindFirstChild("Info");
        local dm = info and info:FindFirstChild("DashMultiplier");
        local bv = Instance.new("BodyVelocity");
        bv.MaxForce = Vector3.new(40000, 0, 40000);
        bv.P = 400000;
        bv.Name = "MovementForce";
        bv.Velocity = hrp.CFrame:VectorToWorldSpace(dirs[dir] or dirs.Right) * (200 * (dm and dm.Value or 1));
        bv.Parent = torso;
        s.debris:AddItem(bv, 0.4);
        return true;
    end;

    function ac.dash(ch, dir)
        if ac.dashlocal(ch, dir) then return true; end;
        return ac.dashforce(ch, dir);
    end;

    local ftrack, ftime = nil, 0;
    function ac.feint()
        local ch = s.lp.Character;
        if not ch or ch:GetAttribute("Moveset") ~= "Itadori" then return; end;
        ftime = os.clock();
        ac.firesvc("ItadoriService", "RightActivated", nil);
        task.defer(function()
            if ch ~= s.lp.Character then return; end;
            local hum = ch:FindFirstChildOfClass("Humanoid");
            local an = hum and hum:FindFirstChildOfClass("Animator");
            if not an then return; end;
            local best, bt = nil, math.huge;
            for _, tr in ut.tracks(an) do
                local tp = tr.TimePosition or math.huge;
                if tp < bt then bt, best = tp, tr; end;
            end;
            if not best then return; end;
            ftrack = best;
            best.Stopped:Once(function()
                if ftrack == best then ftrack = nil; end;
            end);
        end);
    end;

    function ac.feintblocked()
        if not ftrack then return false; end;
        local ok, p = pcall(function() return ftrack.IsPlaying; end);
        if ok and p then return true; end;
        ftrack = nil;
        return false;
    end;

    function ac.skipbf()
        return os.clock() - ftime < 0.45;
    end;

    function ac.dfcd()
        local pg = s.lp:FindFirstChildWhichIsA("PlayerGui");
        local main = pg and pg:FindFirstChild("Main");
        local ms = main and main:FindFirstChild("Moveset");
        local df = ms and ms:FindFirstChild("Divergent Fist");
        if not df then return false; end;
        local cd = df:FindFirstChild("Cooldown");
        if not cd then return false; end;
        return cd.Size.Y.Scale > 0;
    end;

    return ac;
end;

end)();
local _M9 = (function()
return function(ctx)
    local s, ut, opt = ctx.svc, ctx.ut, ctx.opt;
    local tk = {};

    local pc = {
        data = ut.weak(),
        pingbuf = {}, pingmax = 20, pingidx = 0, pingcnt = 0,
    };
    tk.data = pc.data;

    local pingitem = s.pingitem;
    local pcv, pct = 0, 0;
    function tk.ping()
        local n = os.clock();
        if n - pct < 0.15 then return pcv; end;
        pct = n;
        if pingitem then
            local ok, v = pcall(pingitem.GetValue, pingitem);
            pcv = ok and v or 0;
        end;
        return pcv;
    end;

    local pwt, pwts = {}, {};
    do
        local w, sum = 1, 0;
        for i = 1, pc.pingmax do pwt[i] = w; sum += w; pwts[i] = sum; w *= 1.15; end;
    end;

    local spv, spt = 0, 0;
    function tk.sping()
        local n = os.clock();
        if n - spt < 0.1 then return spv; end;
        spt = n;
        local buf, max = pc.pingbuf, pc.pingmax;
        pc.pingidx = pc.pingidx % max + 1;
        buf[pc.pingidx] = tk.ping();
        if pc.pingcnt < max then pc.pingcnt += 1; end;
        local cnt = pc.pingcnt;
        if cnt == 0 then spv = 0; return 0; end;
        local sum = 0;
        local oldest = cnt < max and 1 or pc.pingidx % max + 1;
        for i = 0, cnt - 1 do
            sum += (buf[(oldest - 1 + i) % max + 1] or 0) * pwt[i + 1];
        end;
        spv = sum / pwts[cnt];
        return spv;
    end;

    local fpsv = 60;
    function tk.fps()
        return fpsv;
    end;

    function tk.upd(char, hrp)
        if not char then return; end;
        hrp = hrp or ut.hrp(char);
        if not hrp then return; end;
        local now = os.clock();
        local cv, cp = hrp.AssemblyLinearVelocity, hrp.Position;
        local d = pc.data[char];
        if not d then
            pc.data[char] = {
                svel = cv, saccel = Vector3.zero, lastvel = cv, lastt = now,
                lastpos = cp, posbuf = {}, posidx = 0, poscnt = 0, posmax = 6,
                conf = 0.5, dirchg = 0, angvel = 0, angaccel = 0, lastlook = hrp.CFrame.LookVector,
            };
            return;
        end;
        local dt = now - d.lastt;
        if dt <= 0.001 then return; end;
        d.posidx = d.posidx % d.posmax + 1;
        local pb = d.posbuf[d.posidx];
        if pb then pb.p, pb.t = cp, now; else d.posbuf[d.posidx] = { p = cp, t = now }; end;
        if d.poscnt < d.posmax then d.poscnt += 1; end;
        local pdvel = (cp - d.lastpos) / dt;
        pdvel = Vector3.new(pdvel.X, 0, pdvel.Z);
        local jth = math.max(d.svel.Magnitude * 2.5, 30);
        local uv = (cv - d.svel).Magnitude < jth and cv or d.svel:Lerp(cv, 0.15);
        local od = Vector3.new(d.svel.X, 0, d.svel.Z);
        local nd = Vector3.new(uv.X, 0, uv.Z);
        local ddot = 1;
        if od.Magnitude > 1 and nd.Magnitude > 1 then ddot = od.Unit:Dot(nd.Unit); end;
        d.dirchg += (math.clamp(1 - ddot, 0, 2) - d.dirchg) * 0.4;
        local ba = math.clamp(dt * 25, 0.3, 0.85);
        local urg = math.clamp(d.dirchg * 3, 0, 1);
        d.svel = d.svel:Lerp(uv:Lerp(pdvel, 0.2), ba + (1 - ba) * urg);
        local ia = (uv - d.lastvel) / dt;
        if ia.Magnitude > 200 then ia = ia.Unit * 200; end;
        d.saccel = d.saccel:Lerp(ia, math.min(math.clamp(dt * 12, 0.1, 0.5) + urg * 0.3, 0.9));
        local rc = math.clamp((ddot + 1) * 0.5, 0, 1);
        local sc = math.clamp(d.svel.Magnitude / 8, 0, 1);
        d.conf += (rc * sc - d.conf) * math.clamp(dt * 8, 0.1, 0.6);
        local clk = hrp.CFrame.LookVector;
        local cl2 = Vector3.new(clk.X, 0, clk.Z);
        local ll2 = Vector3.new(d.lastlook.X, 0, d.lastlook.Z);
        if cl2.Magnitude > 0.01 and ll2.Magnitude > 0.01 then
            local rang = math.asin(math.clamp(ll2.Unit:Cross(cl2.Unit).Y, -1, 1)) / dt;
            local pav = d.angvel;
            d.angvel += (rang - d.angvel) * math.clamp(dt * 15, 0.15, 0.6);
            local raa = math.clamp((d.angvel - pav) / dt, -50, 50);
            d.angaccel += (raa - d.angaccel) * math.clamp(dt * 10, 0.1, 0.5);
        end;
        d.lastlook, d.lastvel, d.lastpos, d.lastt = clk, uv, cp, now;
    end;

    function tk.predict(char, extra)
        local d = pc.data[char];
        local hrp = ut.hrp(char);
        if not hrp then return nil; end;
        local pos = hrp.Position;
        if not d then return pos; end;
        local t = tk.sping() / 1000 + 1 / math.max(tk.fps(), 30) * 0.5 + (extra or 0);
        t *= (tonumber(opt("PredictStrength", 1)) or 1);
        if opt("PredSmoothComp", false) == true then
            local sm = tonumber(opt("LockSmoothing", 0)) or 0;
            if sm > 0.05 then t += sm * (tonumber(opt("PredSmoothCompMul", 0.15)) or 0.15); end;
        end;
        local spd = d.svel.Magnitude;
        local sf = math.clamp(spd / 6, 0, 1);
        sf *= sf;
        local ct = t * math.clamp(d.conf * 1.2, 0.15, 1) * sf;
        local pred = pos + d.svel * ct + 0.5 * d.saccel * ct * ct;
        if d.poscnt >= 3 then
            local o = d.posbuf[d.posidx % d.posmax + 1];
            if o then
                local adt = os.clock() - o.t;
                if adt > 0.05 then
                    local tv = (pos - o.p) / adt;
                    pred = pred:Lerp(pos + Vector3.new(tv.X, 0, tv.Z) * ct, 0.15 * (1 - d.conf));
                end;
            end;
        end;
        local delta = pred - pos;
        local maxd = math.clamp(spd * t * 1.8, 5, 40);
        if delta.Magnitude > maxd then pred = pos + delta.Unit * maxd; end;
        return pred;
    end;

    local dashids, sdpred = {}, ut.weak();
    for _, v in s.movefld:GetChildren() do
        if v:IsA("Animation") and (v.Name == "DashRight" or v.Name == "DashLeft") then
            dashids[v.AnimationId] = true;
        end;
    end;
    tk.dashids = dashids;

    
    
    tk.dashnids = {};
    do
        local fl = ctx.filter;
        for id in next, dashids do
            tk.dashnids[fl and fl.normid(id) or id] = true;
        end;
    end;

    function tk.sidedash(char)
        local till = sdpred[char];
        if till then
            if till > os.clock() then return true; end;
            sdpred[char] = nil;
        end;
        local hum = char and char:FindFirstChild("Humanoid");
        local an = hum and hum:FindFirstChildOfClass("Animator");
        if not an then return false; end;
        for _, tr in ut.tracks(an) do
            local a = tr.Animation;
            if a and dashids[a.AnimationId] then
                sdpred[char] = os.clock() + 0.2;
                return true;
            end;
        end;
        return false;
    end;

    local conn, acc = nil, 0;
    local nchk, nval = 0, false;

    local function need()
        local n = os.clock();
        if n - nchk < .25 then return nval; end;
        nchk = n;
        nval = opt("BFCBackPred", false) == true
            or opt("BBBackPred", false) == true
            or opt("SDABackPred", false) == true
            or opt("LockOn", false) == true;
        return nval;
    end;
    tk.need = need;

    function tk.start()
        if conn then return; end;
        conn = s.runs.Heartbeat:Connect(function(dt)
            if dt > 0 then fpsv += (1 / dt - fpsv) * 0.08; end;
            acc += dt;
            if acc < 0.03 then return; end;
            acc = 0;
            if not need() then return; end;
            local me = ut.hrp(s.lp.Character);
            if not me then return; end;
            local mp = me.Position;
            local r = math.max(tonumber(opt("LockRange", 200)) or 200, 150) + 50;
            r *= r;
            for _, c in ut.chars() do
                local h = ut.hrp(c);
                if h and ut.dist2sq(mp, h.Position) <= r then tk.upd(c, h); end;
            end;
        end);
        ut.add(conn);
    end;

    function tk.stop()
        if not conn then return; end;
        conn:Disconnect();
        conn = nil;
    end;

    return tk;
end;

end)();
local _M10 = (function()
return function(ctx)
    local s, ut, opt = ctx.svc, ctx.ut, ctx.opt;
    local tk = ctx.track;
    local lk = {};

    local scf, lastf = nil, 0;

    function lk.face(hrp, hum, pos)
        if not (hrp and hum and pos) then return; end;
        if hum.AutoRotate then hum.AutoRotate = false; end;
        local hp = hrp.Position;
        local ld = Vector3.new(pos.X - hp.X, 0, pos.Z - hp.Z);
        if ld.Magnitude <= 0.01 then return; end;
        local tcf = CFrame.new(hp, hp + ld);
        if not scf then scf = tcf; end;
        local now = os.clock();
        local dt = math.clamp(now - lastf, 1 / 240, .25);
        lastf = now;
        local sm = math.clamp(tonumber(opt("LockSmoothing", 0)) or 0, 0, 1);
        local a = sm <= .01 and 1 or math.clamp(1 - math.exp(-dt / (sm * .35)), 0, 1);
        scf = (scf - scf.Position):Lerp(tcf - tcf.Position, a) + hp;
        hrp.CFrame = scf;
    end;

    function lk.resetrot()
        local ch = s.lp.Character;
        local hum = ch and ch:FindFirstChildOfClass("Humanoid");
        if not hum then return; end;
        hum.AutoRotate = true;
    end;

    local camon = false;
    local CAMD, CAMH, MIND = 13, 3.5, 11;

    function lk.relcam()
        if not camon then return; end;
        camon = false;
        local cam = workspace.CurrentCamera;
        if cam and cam.CameraType == Enum.CameraType.Scriptable then
            cam.CameraType = Enum.CameraType.Custom;
        end;
    end;

    function lk.facecam(hrp, tgt, pos, dt)
        local cam = workspace.CurrentCamera;
        if not (cam and hrp and pos) then return; end;
        local dir = pos - hrp.Position;
        local dist = math.max(dir.Magnitude, MIND);
        local flat = Vector3.new(dir.X, 0, dir.Z);
        if flat.Magnitude < .5 then
            local cl = cam.CFrame.LookVector;
            flat = Vector3.new(cl.X, 0, cl.Z);
        end;
        if flat.Magnitude < .01 then flat = Vector3.new(0, 0, -1); end;
        flat = flat.Unit;
        local right = Vector3.new(0, 1, 0):Cross(flat);
        local cpos = hrp.Position
            - flat * math.clamp(dist, MIND, CAMD)
            + Vector3.new(0, CAMH + (tonumber(opt("LockCamY", 0)) or 0), 0)
            + right * (tonumber(opt("LockCamX", 0)) or 0)
            + flat * (tonumber(opt("LockCamZ", 0)) or 0);
        cam.CameraType = Enum.CameraType.Scriptable;
        camon = true;
        local sm = math.clamp(tonumber(opt("LockSmoothing", 0)) or 0, 0, 1);
        local base = sm <= .01 and .95 or math.clamp(1 - math.exp(-dt / (sm * .35)), .05, .95);
        local th = tgt and ut.hrp(tgt);
        local a = th and math.clamp(base + th.AssemblyLinearVelocity.Magnitude * .35 * dt, base, math.min(base + .3, .95)) or base;
        cam.CFrame = cam.CFrame:Lerp(CFrame.new(cpos, pos), a);
    end;

    local hist, histmax, histidx, histcnt = {}, 12, 0, 0;
    for i = 1, histmax do hist[i] = { t = 0, lk = Vector3.zero }; end;
    local angvel, lastlk, lastt, aoff, atgt, velema = 0, nil, 0, 0, nil, Vector3.zero;

    function lk.aareset()
        histidx, histcnt, angvel, lastlk, lastt, aoff, atgt, velema = 0, 0, 0, nil, 0, 0, nil, Vector3.zero;
    end;

    function lk.reset()
        scf, lastf = nil, 0;
        lk.aareset();
        lk.resetrot();
        lk.relcam();
    end;

    function lk.aaupdate(tgt, lhrp)
        if opt("DFArcAutoAngle", false) ~= true then
            if aoff ~= 0 then
                aoff *= 0.8;
                if math.abs(aoff) < 0.3 then aoff = 0; end;
            end;
            return aoff;
        end;
        if not (tgt and lhrp) then aoff = 0; return 0; end;
        local thrp = ut.hrp(tgt);
        if not thrp then aoff = 0; return 0; end;
        if tgt ~= atgt then lk.aareset(); atgt = tgt; end;
        local now = os.clock();
        local dt = now - lastt;
        if dt < 0.016 then return aoff; end;
        lastt = now;
        local tl = thrp.CFrame.LookVector;
        tl = Vector3.new(tl.X, 0, tl.Z);
        if tl.Magnitude < 0.01 then return aoff; end;
        tl = tl.Unit;
        if lastlk then
            local da = math.atan2(lastlk:Cross(tl).Y, lastlk:Dot(tl));
            angvel = angvel * 0.65 + (da / math.max(dt, 0.001)) * 0.35;
        end;
        lastlk = tl;
        histidx = histidx % histmax + 1;
        if histcnt < histmax then histcnt += 1; end;
        local he = hist[histidx];
        he.t, he.lk = now, tl;
        local tv = thrp.AssemblyLinearVelocity;
        velema = velema * 0.7 + Vector3.new(tv.X, 0, tv.Z) * 0.3;
        local lp2, tp2 = lhrp.Position, thrp.Position;
        local topl = Vector3.new(lp2.X - tp2.X, 0, lp2.Z - tp2.Z);
        if topl.Magnitude < 0.1 then return aoff; end;
        topl = topl.Unit;
        local fdot = tl:Dot(topl);
        local behind = math.clamp(-fdot, 0, 1);
        local facesign = tl:Cross(topl).Y >= 0 and -1 or 1;
        local velmix, velsign = 0, 0;
        if velema.Magnitude > 1.5 then
            velsign = velema.Unit:Cross(topl).Y >= 0 and -1 or 1;
            velmix = math.clamp(velema.Magnitude / 20, 0, 0.45);
        end;
        local boost = (tk and tk.sidedash(tgt)) and 1.6 or 1;
        local angpred = 0;
        if math.abs(angvel) > 0.4 then angpred = math.clamp(angvel * 0.12 * 18, -15, 15); end;
        local histbias = 0;
        if histcnt >= 4 then
            local oi = histcnt < histmax and (histidx - histcnt) % histmax + 1 or histidx % histmax + 1;
            local o, n = hist[oi], hist[histidx];
            local ht = n.t - o.t;
            if ht > 0.08 then
                histbias = math.clamp(math.atan2(o.lk:Cross(n.lk).Y, o.lk:Dot(n.lk)) / ht * 6, -10, 10);
            end;
        end;
        local dirsig = facesign * (1 - velmix) + velsign * velmix;
        dirsig = dirsig >= 0 and 1 or -1;
        local str = math.abs(tonumber(opt("DFArcAngleVal", 15)) or 15);
        local raw = math.clamp(dirsig * behind * str * boost + angpred + histbias * behind, -45, 45);
        if behind < 0.15 then raw *= behind / 0.15; end;
        aoff += (raw - aoff) * 0.85;
        if math.abs(aoff) < 0.3 then aoff = 0; end;
        return aoff;
    end;

    function lk.aoff(lchar, tgt)
        if not tgt then return 0; end;
        if opt("DFArcAutoAngle", false) == true then
            local lhrp, thrp = ut.hrp(lchar), ut.hrp(tgt);
            if not (lhrp and thrp) then return 0; end;
            local mag = tonumber(opt("DFArcAngleVal", 15)) or 15;
            local tl = thrp.CFrame.LookVector;
            tl = Vector3.new(tl.X, 0, tl.Z);
            if tl.Magnitude < 0.01 then return 0; end;
            tl = tl.Unit;
            local lp2, tp2 = lhrp.Position, thrp.Position;
            local topl = Vector3.new(lp2.X - tp2.X, 0, lp2.Z - tp2.Z);
            if topl.Magnitude < 0.1 then return 0; end;
            topl = topl.Unit;
            local sign = tl:Cross(topl).Y >= 0 and -1 or 1;
            local dot = tl:Dot(topl);
            local tv = thrp.AssemblyLinearVelocity;
            local hv = Vector3.new(tv.X, 0, tv.Z);
            if hv.Magnitude > 2 then
                local vs = hv.Unit:Cross(topl).Y >= 0 and -1 or 1;
                local w = math.clamp(hv.Magnitude / 18, 0, 0.4);
                sign = (sign * (1 - w) + vs * w) >= 0 and 1 or -1;
            end;
            local behind = math.clamp(-dot, 0, 1);
            if math.abs(angvel) > 0.5 then
                return math.clamp(sign * behind * math.abs(mag) + math.clamp(angvel * 1.2, -8, 8), -45, 45);
            end;
            return sign * behind * math.abs(mag);
        end;
        if opt("DFArcAngle", false) == true then return tonumber(opt("DFArcAngleVal", 0)) or 0; end;
        return 0;
    end;

    function lk.rotpos(origin, pos, deg)
        if deg == 0 then return pos; end;
        local r = math.rad(deg);
        local dx, dz = pos.X - origin.X, pos.Z - origin.Z;
        local cs, sn = math.cos(r), math.sin(r);
        return Vector3.new(origin.X + dx * cs + dz * sn, pos.Y, origin.Z - dx * sn + dz * cs);
    end;

    function lk.behind(lchar, tgt)
        local lhrp, thrp = ut.hrp(lchar), ut.hrp(tgt);
        if not (lhrp and thrp) then return false; end;
        local tl = thrp.CFrame.LookVector;
        local d = (lhrp.Position - thrp.Position);
        if d.Magnitude < 0.01 then return false; end;
        return tl:Dot(d.Unit) < -0.5;
    end;

    local conn, ftgt, lastpick = nil, nil, 0;
    local ragged, ragt, ragtgt = false, 0, nil;
    function lk.set(tgt)
        ftgt, lk.tgt = tgt, tgt;
    end;

    function lk.running()
        return conn ~= nil;
    end;

    function lk.hold(v)
        lk.held = v == true;
    end;

    local function want()
        if lk.held then return true; end;
        local bfm = ctx.bfc;
        if bfm and bfm.target then return true; end;
        if opt("LockOn", false) == true then return true; end;
        if opt("LockBlock", false) ~= true then return false; end;
        local bk = ctx.block;
        return bk ~= nil and bk.selfblocking() == true;
    end;

    local function closest()
        local ch = s.lp.Character;
        local h = ut.hrp(ch);
        if not h then return nil; end;
        local p, best, bd = h.Position, nil, math.huge;
        for _, c in ut.chars() do
            if c ~= ch and ut.alive(c) then
                local t = ut.hrp(c);
                if t then
                    local d = ut.dist2sq(p, t.Position);
                    if d < bd then best, bd = c, d; end;
                end;
            end;
        end;
        return best;
    end;

    
    
    local function aimpt()
        local cam = workspace.CurrentCamera;
        if not cam then return nil; end;
        if s.uis.TouchEnabled and not s.uis.KeyboardEnabled then
            local v = cam.ViewportSize;
            return Vector2.new(v.X * .5, v.Y * .5), cam;
        end;
        local m = s.uis:GetMouseLocation();
        return Vector2.new(m.X, m.Y), cam;
    end;

    local function onscreen(maxd)
        local aim, cam = aimpt();
        if not aim then return nil; end;
        local ch = s.lp.Character;
        local h = ut.hrp(ch);
        if not h then return nil; end;
        local rsq = maxd * maxd;
        local best, bd = nil, math.huge;
        for _, c in ut.chars() do
            if c ~= ch and ut.alive(c) then
                local t = ut.hrp(c);
                if t and ut.dist2sq(h.Position, t.Position) <= rsq then
                    local p, vis = cam:WorldToViewportPoint(t.Position);
                    if vis then
                        local d = (Vector2.new(p.X, p.Y) - aim).Magnitude;
                        if d < bd then best, bd = c, d; end;
                    end;
                end;
            end;
        end;
        return best;
    end;

    
    
    function lk.aim()
        local maxd = tonumber(opt("LockRange", 200)) or 200;
        if opt("LockTargetMode", "Closest") == "Crosshair" then
            local t = onscreen(maxd);
            if t then return t; end;
        end;
        return closest() or onscreen(maxd);
    end;

    local function named()
        local nm = opt("LockBlockTarget", "None");
        if not nm or nm == "None" then return nil; end;
        for _, c in ut.chars() do
            if c.Name == nm and ut.alive(c) then return c; end;
        end;
        return nil;
    end;

    local function blockdrv()
        if lk.held then return false; end;
        if opt("LockOn", false) == true then return false; end;
        local bfm = ctx.bfc;
        if bfm and bfm.target then return false; end;
        return opt("LockBlock", false) == true;
    end;

    local function pick()
        if opt("LockBlockMode", "Closest") == "Selected" then return named(); end;
        return closest();
    end;

    function lk.arm()
        if opt("LockOn", false) ~= true and opt("LockBlock", false) ~= true then
            lk.stop();
            return;
        end;
        if conn then return; end;
        lk.start(ftgt);
    end;

    function lk.start(tgt)
        lk.set(tgt);
        if conn then return; end;
        conn = s.runs.Heartbeat:Connect(function(dt)
            local bdrv = blockdrv();
            if not want() then
                if scf then scf = nil; lk.resetrot(); end;
                lk.relcam();
                if bdrv and ftgt then lk.set(nil); end;
                return;
            end;
            
            
            
            
            local lch = s.lp.Character;
            if lch and (tonumber(lch:GetAttribute("Ragdoll")) or 0) > 0 then
                if not ragged then
                    ragged, ragt, ragtgt = true, os.clock(), ftgt;
                    if scf then scf = nil; end;
                    lk.set(nil);
                    lk.resetrot();
                    lk.relcam();
                end;
                if os.clock() - ragt > 5 then ragtgt = nil; end;
                return;
            end;
            if ragged then
                ragged = false;
                if ragtgt and ragtgt.Parent and ut.alive(ragtgt) then lk.set(ragtgt); end;
                ragtgt = nil;
            end;
            local t = ftgt;
            if bdrv then
                local now = os.clock();
                if now - lastpick >= 0.25 then
                    lastpick = now;
                    local n = pick();
                    if n and n ~= t then t = n; lk.set(n); end;
                end;
            end;
            if not (t and t.Parent and ut.alive(t)) then
                if bdrv then
                    if ftgt then lk.set(nil); end;
                    return;
                end;
                local now = os.clock();
                if now - lastpick < 0.25 then return; end;
                lastpick = now;
                t = lk.aim() or (ctx.bfc and ctx.bfc.autotgt());
                if not t then return; end;
                lk.set(t);
            end;
            local ch = s.lp.Character;
            local hrp, hum = ut.hrp(ch), ch and ch:FindFirstChildOfClass("Humanoid");
            local thrp = t and ut.hrp(t);
            if not (hrp and hum and thrp) then return; end;
            local pos = (tk and tk.predict(t, 0)) or thrp.Position;
            local off = lk.aaupdate(t, hrp);
            if off == 0 then off = lk.aoff(ch, t); end;
            local m = opt("LockMethod", "Character");
            local aim = lk.rotpos(hrp.Position, pos, off);
            if m ~= "Character" then
                lk.facecam(hrp, t, aim, math.clamp(dt or .016, 1 / 240, .25));
            else
                lk.relcam();
            end;
            if m ~= "Camera" then
                lk.face(hrp, hum, aim);
            elseif scf then
                scf = nil;
                lk.resetrot();
            end;
        end);
        ut.add(conn);
    end;

    function lk.stop()
        ragged, ragtgt = false, nil;
        lk.set(nil);
        if conn then conn:Disconnect(); conn = nil; end;
        lk.reset();
    end;

    return lk;
end;

end)();
local _M11 = (function()
return function(ctx)
    local s, ut, opt = ctx.svc, ctx.ut, ctx.opt;
    local tk, lk, ac = ctx.track, ctx.lock, ctx.act;
    local bf = { en = false, active = false, target = nil, hitidx = 0 };

    local ids = {
        ["rbxassetid://100962226150441"] = true,
        ["rbxassetid://95852624447551"] = true,
        ["rbxassetid://74145636023952"] = true,
        ["rbxassetid://123171106092050"] = true,
    };
    local numids = {
        ["100962226150441"] = true,
        ["95852624447551"] = true,
        ["74145636023952"] = true,
        ["123171106092050"] = true,
    };

    local conns, rtok, animlast, feinted, feinttime, mandb = {}, 0, 0, false, 0, 0;
    local lockconn, lkown, lktok = nil, false, 0;

    local function isid(id)
        if not id then return false; end;
        if ids[id] then return true; end;
        local n = tostring(id):match("%d+");
        return n ~= nil and numids[n] == true;
    end;
    bf.isid = isid;

    local function bo(p, k, d)
        if opt(p .. "Customize", false) ~= true then return d; end;
        local v = opt(p .. k, nil);
        if v == nil then return d; end;
        return v;
    end;

    local function num(p, k, d)
        return tonumber(bo(p, k, d)) or d;
    end;

    local function on(p, k)
        return opt(p .. k, false) == true;
    end;

    local function nostick(p)
        if p == "BFC" then return opt("DFArcNoStick", false) == true; end;
        return on(p, "NoStick");
    end;

    local function flat(v)
        return Vector3.new(v.X, 0, v.Z);
    end;

    function bf.ease(t, p)
        p = p or "BFC";
        if not on(p, "Curve") then return 1; end;
        local mode = bo(p, "CurveType", "Ease-Out");
        if on(p, "CycleCurve") then
            mode = ({ "Ease-In", "Ease-Out", "Ease-In-Out" })[bf.hitidx % 3 + 1];
        end;
        local fl = num(p, "CurveFloor", 0.08);
        local e = math.max(num(p, "CurvePow", 3) - 1, 0.01);
        if mode == "Linear" then return 1; end;
        if mode == "Ease-In" then return math.max(t ^ e, fl); end;
        if mode == "Ease-In-Out" then
            if t < 0.5 then return math.max((2 * t) ^ e, fl); end;
            return math.max((2 - 2 * t) ^ e, fl);
        end;
        return math.max((1 - t) ^ e, fl);
    end;

    local function dmmult(p)
        if on(p, "Curve") and on(p, "CurveDash") then return bf.ease(0, p); end;
        return 1;
    end;

    function bf.closest(maxd)
        local ch = s.lp.Character;
        local hrp = ut.hrp(ch);
        if not hrp then return nil; end;
        maxd = tonumber(maxd) or tonumber(opt("DFArcDist", 30)) or 30;
        local best, bd = nil, maxd * maxd;
        for _, c in ut.chars() do
            if c ~= ch and ut.alive(c) then
                local h = ut.hrp(c);
                if h then
                    local d = ut.dist2sq(hrp.Position, h.Position);
                    if d < bd then bd, best = d, c; end;
                end;
            end;
        end;
        return best;
    end;

    function bf.autotgt()
        return bf.pick and bf.pick() or bf.closest();
    end;

    local function getdir(tgt, p)
        if on(p, "Backflip") then return "Back"; end;
        local hrp, thrp = ut.hrp(s.lp.Character), ut.hrp(tgt);
        if not (hrp and thrp) then return "Right"; end;
        local lkv = flat(thrp.CFrame.LookVector);
        if lkv.Magnitude < 0.01 then return "Right"; end;
        local back = thrp.Position - lkv.Unit * num(p, "ArcRadius", 5);
        local toback = flat(back - hrp.Position);
        if toback.Magnitude < 0.01 then return "Right"; end;
        local rv = flat(hrp.CFrame.RightVector);
        if rv.Magnitude < 0.01 then return "Right"; end;
        return toback.Unit:Dot(rv.Unit) >= 0 and "Right" or "Left";
    end;

    local function predlook(tgt, t)
        local thrp = ut.hrp(tgt);
        if not thrp then return nil; end;
        local l = flat(thrp.CFrame.LookVector);
        if l.Magnitude < 0.01 then return nil; end;
        l = l.Unit;
        local d = tk.data[tgt];
        if not d then return l; end;
        local a = math.clamp(d.angvel * t + 0.5 * d.angaccel * t * t, -2.4, 2.4);
        local cs, sn = math.cos(a), math.sin(a);
        return Vector3.new(l.X * cs - l.Z * sn, 0, l.X * sn + l.Z * cs).Unit;
    end;

    local function backpos(tgt, p)
        p = p or "BFC";
        local thrp = ut.hrp(tgt);
        if not thrp then return nil; end;
        local pos = thrp.Position;
        local l = flat(thrp.CFrame.LookVector);
        if l.Magnitude < 0.01 then return nil; end;
        l = l.Unit;
        if on(p, "BackPred") then
            local str = tonumber(opt(p .. "BackPredStrength", 1)) or 1;
            local t = (tk.sping() / 1000 + 1 / math.max(tk.fps(), 30) * 0.5) * str;
            local pp = tk.predict(tgt, 0);
            if pp then pos = pos:Lerp(pp, math.clamp(str, 0, 2)); end;
            local pl = predlook(tgt, t);
            if pl then l = pl; end;
        end;
        return pos - l * num(p, "ArcRadius", 5), l, pos;
    end;
    bf.backpos = backpos;

    local function firedf(ch)
        local ms = ch and ch:FindFirstChild("Moveset");
        local tool = ms and ms:FindFirstChild("Divergent Fist");
        if tool then s.dfact:FireServer(tool, nil); end;
    end;

    local abfconn;
    function bf.abfstop()
        if abfconn then abfconn:Disconnect(); abfconn = nil; end;
    end;

    function bf.abfstart()
        bf.abfstop();
        if not s.dfefx then return false; end;
        abfconn = s.dfefx.OnClientEvent:Connect(function(kind, who)
            if kind ~= "CurseBuild" or who ~= s.lp.Character then return; end;
            local d = tonumber(opt("ABFDelay", 0.1)) or 0.1;
            if d > 0 then task.wait(d); end;
            if not abfconn or ac.skipbf() or ac.feintblocked() then return; end;
            firedf(s.lp.Character);
        end);
        ut.add(abfconn);
        return true;
    end;

    local function calcdm(tgt, p)
        local hrp, thrp = ut.hrp(s.lp.Character), ut.hrp(tgt);
        if not (hrp and thrp) then return 1; end;
        if on(p, "ArcOver") then return 0.15 * dmmult(p); end;
        local _, l = backpos(tgt, p);
        if not l then return 1; end;
        local tr = num(p, "ArcRadius", 5);
        local d = flat(hrp.Position - thrp.Position);
        local sr = math.max(d.Magnitude, 0.01);
        local sa = math.atan2(d.X, d.Z);
        local ta = math.atan2(-l.X, -l.Z);
        local da = (ta - sa + math.pi) % (2 * math.pi) - math.pi;
        local avg = (sr + tr) * 0.5;
        local arc = math.abs(da) * avg;
        local rad = math.abs(sr - tr);
        local total = math.sqrt(arc * arc + rad * rad);
        return math.clamp(total / 20 * 1.15, 0.15, num(p, "DashMultCap", 1.5)) * dmmult(p);
    end;

    local function redirect(tgt, p)
        rtok += 1;
        local tok = rtok;
        task.spawn(function()
            local ch = s.lp.Character;
            local torso = ch and ch:FindFirstChild("Torso");
            local hrp = ut.hrp(ch);
            local thrp = ut.hrp(tgt);
            if not (torso and hrp and thrp) then return; end;
            local bv, w = nil, 0;
            repeat
                bv = torso:FindFirstChild("MovementForce");
                if bv then break; end;
                w += task.wait();
            until w >= 0.08;
            if not (bv and bv:IsA("BodyVelocity")) or rtok ~= tok then return; end;
            local over = on(p, "ArcOver");
            local hgt = num(p, "ArcHeight", 12);
            local sp = hrp.Position;
            local ogmf = bv.MaxForce;
            bv.MaxForce = Vector3.new(math.huge, over and math.huge or ogmf.Y, math.huge);
            local nv = bv:FindFirstChildWhichIsA("NumberValue");
            if nv then pcall(nv.Destroy, nv); end;
            bv.Velocity = Vector3.zero;
            if over then hrp.AssemblyLinearVelocity = Vector3.zero; end;
            local tr = num(p, "ArcRadius", 5);
            local ec = thrp.Position;
            local d0 = flat(hrp.Position - ec);
            local sr = math.max(d0.Magnitude, 3);
            local sa = math.atan2(d0.X, d0.Z);
            local _, l0 = backpos(tgt, p);
            if not l0 then bv.MaxForce = ogmf; return; end;
            local ta = math.atan2(-l0.X, -l0.Z);
            local da0 = (ta - sa + math.pi) % (2 * math.pi) - math.pi;
            local sweep = da0 >= 0 and 1 or -1;
            local totalT = num(p, "ArcDuration", 0.4);
            local lockp = on(p, "LockArc");
            local fixc = lockp and (thrp.Position + flat(thrp.AssemblyLinearVelocity) * (totalT * 0.4)) or nil;
            local arcl = over and (flat(sp - (ec - l0 * tr)).Magnitude + hgt * 2) or math.abs(da0) * math.max(sr, tr);
            local maxspd = math.clamp(arcl / totalT * 2.5, 20, num(p, "MaxArcSpeed", 120));
            local t0 = os.clock();
            local conn, nvconn;
            nvconn = bv.ChildAdded:Connect(function(c)
                if c:IsA("NumberValue") then pcall(c.Destroy, c); end;
            end);
            conn = s.runs.Stepped:Connect(function()
                if rtok ~= tok or not bv.Parent or not thrp.Parent then return; end;
                local el = os.clock() - t0;
                local t = math.clamp(el / totalT, 0, 1);
                local cda = da0;
                if not (lockp or over) then
                    local lc = flat(thrp.CFrame.LookVector);
                    if lc.Magnitude > 0.01 then
                        lc = lc.Unit;
                        local ca = math.atan2(-lc.X, -lc.Z);
                        cda = (ca - sa + math.pi) % (2 * math.pi) - math.pi;
                        if cda * sweep < 0 then cda += sweep * 2 * math.pi; end;
                    end;
                end;
                local st = 1 - (1 - t) ^ 3;
                local fec = fixc or (thrp.Position + flat(thrp.AssemblyLinearVelocity) * (math.max(totalT - el, 0.01) * 0.4));
                local arcpos;
                if over then
                    local lo = l0;
                    if not lockp then
                        local lc = flat(thrp.CFrame.LookVector);
                        if lc.Magnitude > 0.01 then lo = lc.Unit; end;
                    end;
                    local bp = fec - lo * tr;
                    arcpos = Vector3.new(sp.X + (bp.X - sp.X) * st, sp.Y + hgt * math.sin(math.pi * t), sp.Z + (bp.Z - sp.Z) * st);
                else
                    local ang = sa + cda * st;
                    local r = math.max(sr + (tr - sr) * st, tr);
                    arcpos = Vector3.new(fec.X, hrp.Position.Y, fec.Z) + Vector3.new(math.sin(ang), 0, math.cos(ang)) * r;
                end;
                local toarc = arcpos - hrp.Position;
                local dist = toarc.Magnitude;
                if dist < 0.2 and st > 0.9 then bv.Velocity = Vector3.zero; return; end;
                if dist < 0.01 then return; end;
                local sm = bf.ease(t, p);
                local vel = toarc * (20 * sm);
                bv.Velocity = vel.Unit * math.min(vel.Magnitude, maxspd * sm);
            end);
            task.delay(totalT + 0.03, function()
                if conn then conn:Disconnect(); conn = nil; end;
                if nvconn then nvconn:Disconnect(); nvconn = nil; end;
                if bv and bv.Parent then bv.MaxForce = ogmf; end;
                if rtok ~= tok then return; end;
                local h2, t2 = ut.hrp(s.lp.Character), ut.hrp(tgt);
                if not (h2 and t2) then return; end;
                local want = fixc and (fixc - l0 * tr) or nil;
                if not want then
                    local _, l2 = backpos(tgt, p);
                    if not l2 then return; end;
                    want = t2.Position - l2 * tr;
                end;
                local cd = flat(want - h2.Position);
                local m = cd.Magnitude;
                if m > 0.3 and m <= 12 then
                    local cbv = Instance.new("BodyVelocity");
                    cbv.Name = "DFCorr";
                    cbv.MaxForce = Vector3.new(80000, 0, 80000);
                    cbv.P = 80000;
                    cbv.Velocity = cd.Unit * math.min(m / 0.12, num(p, "CorrectionSpeed", 150));
                    cbv.Parent = h2;
                    s.debris:AddItem(cbv, 0.12);
                end;
                local look = flat(t2.Position - h2.Position);
                if look.Magnitude > 0.01 then
                    h2.CFrame = CFrame.new(h2.Position, h2.Position + look);
                end;
            end);
        end);
    end;

    function bf.startlock(tgt)
        if opt("BFCAutoLock", false) ~= true then return; end;
        lktok += 1;
        bf.target = tgt;
        if opt("LockOn", false) == true then
            if not lk.running() then lkown = true; end;
            lk.start(tgt);
            return;
        end;
        if lockconn then lockconn:Disconnect(); end;
        lockconn = s.runs.Heartbeat:Connect(function()
            local t = bf.target;
            local ch = s.lp.Character;
            local hrp, hum = ut.hrp(ch), ch and ch:FindFirstChildOfClass("Humanoid");
            local thrp = t and ut.hrp(t);
            if not (hrp and hum and thrp) then return; end;
            lk.aaupdate(t, hrp);
            local off = lk.aoff(ch, t);
            lk.face(hrp, hum, off ~= 0 and lk.rotpos(hrp.Position, thrp.Position, off) or thrp.Position);
        end);
        ut.add(lockconn);
    end;

    function bf.stoplock()
        bf.target = nil;
        if lockconn then lockconn:Disconnect(); lockconn = nil; end;
        if lkown then lkown = false; lk.stop(); return; end;
        lk.aareset();
        if not lk.running() then lk.reset(); end;
    end;

    local function lockhold(to)
        local my = lktok;
        local ch = s.lp.Character;
        local hum = ch and ch:FindFirstChildOfClass("Humanoid");
        local an = hum and hum:FindFirstChildOfClass("Animator");
        if not an then bf.stoplock(); return; end;
        local done, wc = false, nil;
        local function fin()
            if done then return; end;
            done = true;
            if wc then wc:Disconnect(); wc = nil; end;
            if my ~= lktok then return; end;
            bf.stoplock();
        end;
        task.delay(to, fin);
        for _, tr in an:GetPlayingAnimationTracks() do
            local a = tr.Animation;
            if a and isid(a.AnimationId) then tr.Stopped:Once(fin); return; end;
        end;
        wc = an.AnimationPlayed:Connect(function(tr)
            local a = tr.Animation;
            if not (a and isid(a.AnimationId)) then return; end;
            wc:Disconnect();
            wc = nil;
            tr.Stopped:Once(fin);
        end);
    end;

    local function snapface(tgt)
        local hrp, thrp = ut.hrp(s.lp.Character), ut.hrp(tgt);
        if not (hrp and thrp) then return; end;
        local d = flat(thrp.Position - hrp.Position);
        if d.Magnitude > 0.01 then hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + d); end;
    end;

    local function setdm(ch, mult)
        local info = ch:FindFirstChild("Info");
        if not info then return nil; end;
        local dm = info:FindFirstChild("DashMultiplier");
        local had, old = dm ~= nil, dm and dm.Value or nil;
        if not dm then
            dm = Instance.new("NumberValue");
            dm.Name = "DashMultiplier";
            dm.Parent = info;
        end;
        dm.Value = mult;
        task.delay(0.42, function()
            if not dm.Parent then return; end;
            if had then dm.Value = old or 1; else pcall(dm.Destroy, dm); end;
        end);
        return dm;
    end;

    local function dodash(tgt, srcid, fromanim)
        if bf.active then return; end;
        if not fromanim and ac.dfcd() then return; end;
        if opt("BFCAutoLock", false) == true then tgt = bf.autotgt() or tgt; end;
        if not tgt then return; end;
        bf.active = true;
        bf.startlock(tgt);
        local ch = s.lp.Character;
        if not (ch and ch:FindFirstChild("Info")) then bf.active = false; bf.stoplock(); return; end;
        local dir = getdir(tgt, "BFC");
        setdm(ch, calcdm(tgt, "BFC"));
        if not fromanim then firedf(ch); end;
        s.dashrem:FireServer(dir);
        ac.dash(ch, dir);
        local skipstick = srcid ~= nil and ctx.filter ~= nil and ctx.filter.name(srcid) == "divergentfist4";
        if not nostick("BFC") and (fromanim or not skipstick) then redirect(tgt, "BFC"); end;
        task.delay(0.3, function()
            if opt("AutoFeintBFC", false) == true and tgt and tgt.Parent and not lk.behind(s.lp.Character, tgt) then
                feinted, feinttime = true, os.clock();
                ac.feint();
                bf.active = false;
                bf.stoplock();
                return;
            end;
            feinted = false;
            if fromanim then ac.blackflash(); end;
            snapface(tgt);
            task.wait(0.15);
            bf.active = false;
            lockhold(2);
        end);
    end;
    bf.dodash = dodash;

    local function trigger(id)
        if not bf.en or bf.active then return; end;
        local n = os.clock();
        if n - animlast < 0.12 or n - feinttime < 0.5 then return; end;
        local tgt = bf.target or bf.autotgt();
        if not tgt then
            animlast = n;
            task.delay(0.3, ac.blackflash);
            return;
        end;
        local hrp, thrp = ut.hrp(s.lp.Character), ut.hrp(tgt);
        if not (hrp and thrp) then return; end;
        local maxd = tonumber(opt("DFArcDist", 30)) or 30;
        if ut.dist2sq(hrp.Position, thrp.Position) > maxd * maxd then return; end;
        animlast = n;
        bf.hitidx += 1;
        task.spawn(dodash, tgt, id, true);
    end;

    local function hook()
        local ch = s.lp.Character;
        local hum = ch and ch:FindFirstChildOfClass("Humanoid");
        if not hum then return; end;
        local an = hum:WaitForChild("Animator", 5);
        if not an then return; end;
        local c = an.AnimationPlayed:Connect(function(tr)
            if not bf.en or bf.active then return; end;
            if os.clock() - feinttime < 0.5 then return; end;
            local a = tr.Animation;
            if a and isid(a.AnimationId) then trigger(a.AnimationId); end;
        end);
        conns[#conns + 1] = c;
        ut.add(c);
    end;

    function bf.start()
        bf.stop();
        bf.en = true;
        hook();
        local c = s.lp.CharacterAdded:Connect(function()
            bf.active = false;
            task.wait(1);
            if bf.en then hook(); end;
        end);
        conns[#conns + 1] = c;
        ut.add(c);
    end;

    function bf.stop()
        bf.en, bf.active = false, false;
        bf.stoplock();
        for i = #conns, 1, -1 do
            conns[i]:Disconnect();
            conns[i] = nil;
        end;
    end;

    local function stunned(ch)
        if (ch:GetAttribute("Ragdoll") or 0) > 0 then return true; end;
        local inf = ch:FindFirstChild("Info");
        if not inf then return false; end;
        if inf:FindFirstChild("Stun") or inf:FindFirstChild("Knockback") or inf:FindFirstChild("NoDash") then return true; end;
        local sk = inf:FindFirstChild("InSkill");
        return sk ~= nil and sk.Value == false;
    end;
    bf.stunned = stunned;

    function bf.arcdash(tgt, p)
        p = p or "BFC";
        local ch = s.lp.Character;
        local hrp, thrp = ut.hrp(ch), tgt and ut.hrp(tgt);
        if not (hrp and thrp) then return false; end;
        local dir = getdir(tgt, p);
        setdm(ch, calcdm(tgt, p));
        s.dashrem:FireServer(dir);
        ac.dash(ch, dir);
        if not nostick(p) then redirect(tgt, p); end;
        return true;
    end;

    function bf.manual()
        local n = os.clock();
        if n - mandb < (tonumber(opt("BFCCooldown", 0.8)) or 0.8) then return; end;
        if bf.active or ac.dfcd() then return; end;
        local ch = s.lp.Character;
        if not ch or stunned(ch) then return; end;
        local mvs = ch:GetAttribute("Moveset") or s.lp:GetAttribute("Moveset");
        if mvs and mvs ~= "Itadori" then return; end;
        local tgt = bf.target or bf.autotgt();
        local hrp, thrp = ut.hrp(ch), tgt and ut.hrp(tgt);
        local maxd = tonumber(opt("DFArcDist", 30)) or 30;
        if not (tgt and hrp and thrp) or ut.dist2sq(hrp.Position, thrp.Position) > maxd * maxd then
            ac.blackflash();
            return;
        end;
        bf.startlock(tgt);
        mandb, bf.active = n, true;
        bf.hitidx += 1;
        bf.arcdash(tgt);
        task.spawn(function()
            task.wait(tonumber(opt("DFArcDelay", 0.4)) or 0.4);
            if opt("AutoFeintBFC", false) == true and tgt.Parent and not lk.behind(s.lp.Character, tgt) then
                feinted, feinttime = true, os.clock();
                ac.feint();
                bf.active = false;
                bf.stoplock();
                return;
            end;
            feinted = false;
            firedf(s.lp.Character);
            snapface(tgt);
            task.wait(0.15);
            bf.active = false;
            lockhold(2);
        end);
    end;

    return bf;
end;

end)();
local _M12 = (function()
return function(ctx)
    local s, ut, fl, dh, ac = ctx.svc, ctx.ut, ctx.filter, ctx.doors, ctx.act;
    local opt = ctx.opt;
    local bk = { en = false, blocking = false, active = {} };
    local active = bk.active;
    local hooks, pool = ut.weak(), {};
    local punchar, hhc, hhtok, mpun = nil, 0, 0, false;
    local blkt = nil;
    local lastct = 0;

    local function lhrp()
        local c = s.lp.Character;
        return c and c:FindFirstChild("HumanoidRootPart");
    end;

    local function multi()
        for t, d in active do
            if d.multi and t.IsPlaying then return true; end;
        end;
        return false;
    end;

    local lastbh = false;

    local function clearact()
        table.clear(active);
        dh.release();
        punchar = nil;
        lastbh = false;
    end;

    function bk.punish(force, rng)
        if not force and not opt("ABPunish", true) then return; end;
        local h = lhrp();
        if not h then return; end;
        local r = rng or opt("ABPunishRange", 25);
        local rsq, p = r * r, h.Position;
        local tc = (punchar and punchar.Parent) and punchar or nil;
        if tc then
            local th = ut.hrp(tc);
            if not th or ut.dist2sq(p, th.Position) > rsq then tc = nil; end;
        end;
        if not tc then
            local lc, near = s.lp.Character, false;
            for _, c in ut.chars() do
                if c ~= lc then
                    local ch = ut.hrp(c);
                    if ch and ut.dist2sq(p, ch.Position) <= rsq then near = true; break; end;
                end;
            end;
            if not near then return; end;
        end;
        s.blockoff:FireServer();
        bk.blocking = false;
        clearact();
        local mv = ac.moveset();
        if mv then ac.firesvc(mv .. "Service", "Activated", false); end;
    end;

    local function schedoff(d)
        hhtok += 1;
        local my = hhtok;
        task.delay(d, function()
            if my == hhtok then bk.unblock(false); end;
        end);
    end;

    function bk.unblock(wp)
        if multi() then
            if wp then mpun = true; end;
            return;
        end;
        local defer = mpun;
        wp = wp or mpun;
        mpun = false;
        local man = not bk.blocking and bk.selfblocking();
        if wp and not defer and not man and not lastbh then wp = false; end;
        clearact();
        if bk.blocking then
            bk.blocking = false;
            s.blockoff:FireServer();
        elseif wp and man then
            s.blockoff:FireServer();
        end;
        if wp and (not opt("ABHoldM1", false) or hhc >= opt("ABHitCount", 1)) then bk.punish(); end;
        hhc, hhtok = 0, hhtok + 1;
    end;

    function bk.refresh()
        if next(active) or dh.hold then
            if not bk.blocking then
                bk.blocking = true;
                s.blockon:FireServer(nil);
                if opt("ABHoldM1", false) then hhc = 0; end;
            end;
            if opt("ABHoldM1", false) and hhc == 0 then hhtok += 1; end;
        elseif bk.blocking then
            if opt("ABHoldM1", false) then
                if hhc == 0 then schedoff(opt("ABHoldTimeout", 2)); end;
            else
                bk.unblock(false);
            end;
        end;
    end;

    local function waitmulti(anm, nid)
        local t0 = os.clock();
        while os.clock() - t0 < 8 do
            local live = false;
            for _, t in anm:GetPlayingAnimationTracks() do
                local a = t.Animation;
                if a and fl.normid(a.AnimationId) == nid then live = true; break; end;
            end;
            if not live then return; end;
            task.wait(0.12);
        end;
    end;

    local function arm(char, track, af, anm, nid)
        if active[track] or not track.IsPlaying then return; end;
        active[track] = { char = char, multi = af and af.multi or false };
        if opt("ABOnlyFilter", false) or fl.punishable(nid) then punchar = char; end;
        local h = lhrp();
        if h then dh.arm(af, h.Position, track); end;
        bk.refresh();
        track.Stopped:Once(function()
            if dh.owns(track) then return; end;
            local extra = af and af.holdextra;
            if af and af.multi then
                task.spawn(function()
                    waitmulti(anm, nid);
                    if not active[track] then return; end;
                    if extra and extra > 0 then task.wait(extra); end;
                    active[track] = nil;
                    bk.refresh();
                end);
            elseif extra and extra > 0 then
                task.delay(extra, function()
                    active[track] = nil;
                    bk.refresh();
                end);
            else
                active[track] = nil;
                bk.refresh();
            end;
        end);
    end;

    local function bwin(af)
        local w = af and af.win;
        if not w then return nil; end;
        for _, f in w do
            if f.k == "Block" and f.on and ((f.b or 0) > 0 or (f.e or -1) >= 0) then return f; end;
        end;
        return nil;
    end;

    local function armwin(char, track, af, anm, nid, w)
        local tp = track.TimePosition;
        local d = (w.b or 0) - tp;
        if d > 0 then
            task.delay(d, function()
                if track.IsPlaying and char.Parent then arm(char, track, af, anm, nid); end;
            end);
        else
            arm(char, track, af, anm, nid);
        end;
        local e = w.e or -1;
        if e >= 0 then
            task.delay(math.max(e - tp, 0), function()
                if active[track] then
                    active[track] = nil;
                    bk.refresh();
                end;
            end);
        end;
    end;

    local function docounter()
        local now = os.clock();
        if now - lastct < 0.25 then return false; end;
        local ch = s.lp.Character;
        local ms = ch and ch:FindFirstChild("Moveset");
        if not ms then return false; end;
        local sa = ch:FindFirstChild("SetAssets");
        local conv = sa and (sa:FindFirstChild("Convergence") or sa:FindFirstChild("JackpotAura"));
        local fired = false;
        for _, c in fl.counterall do
            if not (c.gated and conv) then
                local mv = ms:FindFirstChild(c.mv);
                if mv and ac.firesvc(c.svc, c.ev, mv) then fired = true; end;
            end;
        end;
        local mvs = ch:GetAttribute("Moveset") or s.lp:GetAttribute("Moveset");
        if mvs == "Hakari" then
            if now - (ch:GetAttribute("LastM2") or 0) >= 15 and ac.firesvc("HakariService", "RightActivated") then fired = true; end;
        elseif mvs == "Haruta" then
            if ac.firesvc("HarutaService", "Activated", false) then fired = true; end;
        elseif mvs == "Naoya" then
            if ac.firesvc("NaoyaService", "Ultimate") then fired = true; end;
        end;
        if fired then lastct = now; end;
        return fired;
    end;

    local function facing(ehrp, h)
        local d = h.Position - ehrp.Position;
        local f = Vector3.new(d.X, 0, d.Z);
        if f.Magnitude < 0.01 then return true; end;
        return ehrp.CFrame.LookVector:Dot(f.Unit) > 0;
    end;

    function bk.selfblocking()
        return blkt ~= nil and blkt.IsPlaying == true;
    end;

    local dpt, m1t, dashn = 0, 0, nil;

    local function dashes()
        if dashn then return dashn; end;
        local tkm = ctx.track;
        dashn = tkm and tkm.dashnids or nil;
        return dashn;
    end;

    local function onself(track, nid)
        if fl.selfblock(nid) then blkt = track; end;
        local mi = ctx.misc;
        if mi then mi.onselfanim(nid); end;
        
        
        local dn = dashes();
        if dn and dn[nid] and opt("ABDashPunish", false) == true then
            
            
            
            track.Stopped:Once(function()
                local now = os.clock();
                if now - dpt < .3 then return; end;
                dpt = now;
                task.delay(tonumber(opt("ABDashPunishT", .05)) or .05, function()
                    if opt("ABDashPunish", false) ~= true then return; end;
                    
                    
                    bk.punish(true, math.huge);
                end);
            end);
        end;
        if not fl.hitids[nid] then return; end;
        local bh = fl.blockhit(nid);
        if bh then lastbh = true; end;
        if opt("ABHoldM1", false) and (bk.blocking or bk.selfblocking()) then
            hhc += 1;
            if hhc >= opt("ABHitCount", 1) then bk.unblock(true); else schedoff(opt("ABHoldTimeout", 2)); end;
            return;
        end;
        if bk.blocking then
            local hm = multi();
            bk.unblock(false);
            if bh and not hm and opt("ABPunish", true) then bk.punish(true); end;
            return;
        end;
        
        
        
        
        if opt("ABPunish", true) ~= true then return; end;
        if not bh then return; end;
        if not (bk.selfblocking() or next(active)) then return; end;
        if multi() then mpun = true; else bk.punish(true); end;
    end;

    local function m1catch(char, hrp)
        local h = lhrp();
        if not h then return; end;
        local r = tonumber(opt("M1CatchRange", 30)) or 30;
        local rsq, p = r * r, h.Position;
        if ut.dist2sq(p, hrp.Position) > rsq then return; end;
        if opt("ABOnlyLocked", false) == true then
            local lk = ctx.lock;
            if char ~= (lk and lk.tgt) then return; end;
        else
            local lc, best, bd = s.lp.Character, nil, rsq;
            for _, c in ut.chars() do
                if c ~= lc then
                    local ch = ut.hrp(c);
                    if ch then
                        local d = ut.dist2sq(p, ch.Position);
                        if d <= bd then best, bd = c, d; end;
                    end;
                end;
            end;
            if best ~= char then return; end;
        end;
        local now = os.clock();
        if now - m1t < 0.3 then return; end;
        m1t = now;
        bk.punish(true, r);
    end;

    local function onenemy(char, hrp, anm, track, nid)
        local dn = dashes();
        if dn and dn[nid] then
            if opt("M1Catch", false) == true then m1catch(char, hrp); end;
            return;
        end;
        local af = fl.flags(nid);
        local isblk = fl.blockable(nid);
        local ct = opt("AutoCounter", false) == true;
        if not isblk and not (ct and af and af.counter) then return; end;
        local h = lhrp();
        if not h then return; end;
        if not (af and af.lockbypass) then
            if opt("ABOnlyLocked", false) then
                local lk = ctx.lock;
                if char ~= (lk and lk.tgt) then return; end;
            end;
            if opt("ABOnlySelected", false) == true and char.Name ~= opt("ABTarget", "None") then return; end;
        end;
        local dsq = ut.dist2sq(h.Position, hrp.Position);
        local rsq = fl.rangesq(af, opt("ABRange", 20));
        local inarc = true;
        if opt("ABOnlyAngle", false) == true then
            inarc = ut.flat(h.CFrame.LookVector):Dot(ut.flat(hrp.Position - h.Position)) >= math.cos(math.rad((tonumber(opt("ABAngle", 90)) or 90) * 0.5));
        end;
        if bk.en and isblk and inarc and dsq <= rsq then
            local w = bwin(af);
            if w then armwin(char, track, af, anm, nid, w); else arm(char, track, af, anm, nid); end;
        end;
        if not ct or (af and af.counter == false) then return; end;
        local ctsq = fl.ctrangesq(af, opt("CTRange", 25));
        if dsq > ctsq then return; end;
        task.spawn(function()
            local ok = fl.ctwait(af, h, hrp);
            if not ok or not track.IsPlaying or not hrp.Parent then return; end;
            local hh = lhrp();
            if not hh then return; end;
            if ut.dist2sq(hh.Position, hrp.Position) > ctsq then return; end;
            if opt("CTFront", false) and not facing(hrp, hh) then return; end;
            docounter();
        end);
    end;

    local vison, vi, vla, vra, vconn = false, {}, nil, nil, nil;

    local function visdel()
        for _, o in vi do pcall(o.Destroy, o); end;
        table.clear(vi);
        vla, vra = nil, nil;
    end;

    function bk.visgeo()
        if not vla then return; end;
        local r = tonumber(opt("ABRange", 20)) or 20;
        local a = math.rad((tonumber(opt("ABAngle", 90)) or 90) * 0.5);
        local sn, cs = math.sin(a) * r, math.cos(a) * r;
        vla.Position = Vector3.new(-sn, 0, -cs);
        vra.Position = Vector3.new(sn, 0, -cs);
    end;

    local function vismake()
        visdel();
        local h = lhrp();
        if not h then return; end;
        local o = Instance.new("Attachment");
        o.Parent = h;
        vi[1] = o;
        vla, vra = Instance.new("Attachment"), Instance.new("Attachment");
        local col = ColorSequence.new(Color3.fromRGB(90, 165, 255));
        local tr = NumberSequence.new(0.25);
        for i, t in { vla, vra } do
            t.Parent = h;
            vi[i + 1] = t;
            local b = Instance.new("Beam");
            b.Attachment0, b.Attachment1 = o, t;
            b.Color, b.Transparency = col, tr;
            b.Width0, b.Width1 = 0.2, 0.2;
            b.FaceCamera, b.Segments, b.LightInfluence = true, 1, 0;
            b.Parent = t;
        end;
        bk.visgeo();
    end;

    function bk.vis(v)
        vison = v == true;
        if not vison then
            if vconn then vconn:Disconnect(); vconn = nil; end;
            visdel();
            return;
        end;
        vismake();
        if vconn then return; end;
        vconn = s.lp.CharacterAdded:Connect(function(c)
            if not (vison and c:WaitForChild("HumanoidRootPart", 5)) then return; end;
            if vison then vismake(); end;
        end);
    end;

    local function hook(char)
        if hooks[char] then return; end;
        local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5);
        local anm = hum and (hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 5));
        if not anm or not char.Parent then return; end;
        local islp = char == s.lp.Character or s.plrs:GetPlayerFromCharacter(char) == s.lp;
        local hrp = ut.hrp(char);
        local h = {};
        hooks[char] = h;
        h.conn = anm.AnimationPlayed:Connect(function(track)
            local a = track.Animation;
            local id = a and a.AnimationId;
            if not id or id == "" then return; end;
            local nid = fl.normid(id);
            if islp then
                onself(track, nid);
                return;
            end;
            local tp = opt("TPLook", false) == true;
            local hd = opt("HarutaDodge", false) == true;
            local ab = bk.en or opt("AutoCounter", false) == true;
            local m1 = opt("M1Catch", false) == true;
            if not (tp or hd or ab or m1) then return; end;
            hrp = (hrp and hrp.Parent) and hrp or ut.hrp(char);
            if not hrp then return; end;
            local mi = ctx.misc;
            if mi then
                if tp then mi.onlook(char, hrp, nid); end;
                if hd then mi.ondodge(char, hrp, nid); end;
            end;
            if ab or m1 then onenemy(char, hrp, anm, track, nid); end;
        end);
        if #pool > 128 then ut.compact(pool); end;
        pool[#pool + 1] = h.conn;
    end;

    local function drop(char)
        local h = hooks[char];
        if h then
            if h.conn then h.conn:Disconnect(); end;
            hooks[char] = nil;
        end;
        for t, d in active do
            if d.char == char then active[t] = nil; end;
        end;
        if punchar == char then punchar = nil; end;
        bk.refresh();
    end;

    function bk.start()
        if bk.on then return; end;
        bk.on = true;
        for _, c in ut.chars() do hook(c); end;
        pool[#pool + 1] = s.chars.ChildAdded:Connect(function(c) task.defer(hook, c); end);
        pool[#pool + 1] = s.chars.ChildRemoved:Connect(drop);
    end;

    function bk.stop()
        bk.en = false;
        bk.unblock(false);
    end;

    function bk.toggle(v)
        bk.en = v;
        if v then bk.start(); else bk.stop(); end;
    end;

    function bk.unload()
        bk.vis(false);
        for _, c in pool do pcall(function() c:Disconnect(); end); end;
        table.clear(pool);
        table.clear(hooks);
        bk.stop();
    end;

    ut.add({ Disconnect = bk.unload });
    return bk;
end;

end)();
local _M13 = (function()
return function(ctx)
    local s, ut, opt = ctx.svc, ctx.ut, ctx.opt;
    local bf, lk, bk = ctx.bfc, ctx.lock, ctx.block;
    local sd = { active = false };
    local last, lkown = 0, false;

    local function num(k, d)
        return tonumber(opt(k, d)) or d;
    end;

    local function near(c, maxd)
        local hrp, thrp = ut.hrp(s.lp.Character), c and ut.hrp(c);
        if not (hrp and thrp) then return false; end;
        return ut.dist2sq(hrp.Position, thrp.Position) <= maxd * maxd;
    end;

    local function pick(maxd)
        if opt("SDAOnlyLocked", false) == true then
            local t = lk and lk.tgt;
            return (t and t.Parent and ut.alive(t) and near(t, maxd)) and t or nil;
        end;
        if opt("SDAOnlySelected", false) == true then
            local nm = opt("SDATarget", "None");
            if nm == "None" then return nil; end;
            for _, c in ut.chars() do
                if c.Name == nm and ut.alive(c) and near(c, maxd) then return c; end;
            end;
            return nil;
        end;
        return bf.closest(maxd);
    end;

    local function dolock(tgt)
        if opt("SDALock", false) ~= true or lkown then return; end;
        if opt("LockOn", false) == true then return; end;
        lkown = true;
        lk.hold(true);
        lk.start(tgt);
    end;

    local function undolock()
        if not lkown then return; end;
        lkown = false;
        lk.hold(false);
        if opt("LockBlock", false) ~= true then lk.stop(); end;
    end;

    function sd.fire()
        if opt("SDAOn", false) ~= true or sd.active then return false; end;
        local n = os.clock();
        local cd = num("SDACd", .5);
        if n - last < cd then return false; end;
        local ch = s.lp.Character;
        if not ch or bf.stunned(ch) then return false; end;
        local maxd = num("SDADist", 30);
        local tgt = pick(maxd);
        if not tgt then return false; end;
        last, sd.active = n, true;
        dolock(tgt);
        if not bf.arcdash(tgt, "SDA") then
            sd.active = false;
            undolock();
            return false;
        end;
        if bk and opt("SDAPunish", false) == true then
            task.delay(num("SDAPunishT", .12), function()
                if tgt.Parent then bk.punish(true, maxd); end;
            end);
        end;
        task.delay(cd, function()
            sd.active = false;
            undolock();
        end);
        return true;
    end;

    function sd.stop()
        sd.active = false;
        undolock();
    end;

    return sd;
end;

end)();
local _M14 = (function()
return function(ctx)
    local s, ut, opt, num, ac = ctx.svc, ctx.ut, ctx.opt, ctx.cfg.num, ctx.act;
    local fl, lk, bf, tk = ctx.filter, ctx.lock, ctx.bfc, ctx.track;
    local ms = {};
    local jconn, arjump = nil, 0;

    function ms.infjump(v)
        if not v then
            if jconn then jconn:Disconnect(); jconn = nil; end;
            return;
        end;
        if jconn then return; end;
        jconn = s.uis.JumpRequest:Connect(function()
            if os.clock() - arjump < .2 then return; end;
            local h = ut.alive(s.lp.Character);
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping); end;
        end);
    end;

    local fups = {
        feverbreaker = { { f = "AutoHK4", d = .3, svc = "ShutterDoorService", ev = "Activated", mv = "Shutter Doors" } },
        reserveballs = { { f = "AutoHKB", d = .1, svc = "ShutterDoorService", ev = "Activated", mv = "Shutter Doors" } },
        rapidpunches = { { f = "AutoGojo3R", air = true, svc = "GojoService", ev = "RightActivated" } },
        twofoldkick = { { f = "AutoGojo4R", air = true, svc = "GojoService", ev = "RightActivated" } },
        toad = { { f = "AutoMegToad", d = .1, svc = "NueService", ev = "Activated", mv = "Nue", tgt = true } },
        nue = { { f = "AutoMegBird", d = .1, svc = "MegumiService", ev = "RightActivated", noarg = true } },
        shadow = { { f = "AutoMegRabbit", near = "MegRabbitRange", svc = "RabbitEscapeService", ev = "Activated", mv = "Rabbit Escape" } },
        chase = { { f = "AutoRyuDash1", p = "Ryu.Melee.Chase", d = .2, svc = "GraniteBlastService", ev = "Activated", mv = "Granite Blast" } },
        pebblethrow = { { f = "AutoTodoR", d = .9, svc = "TodoService", ev = "RightActivated", noarg = true } },
        backstab = { { f = "AutoBackstab", arc = true } },
        garudarebound = {
            { f = "AutoYGR", d = 1, png = true, ys = 1 },
            { f = "AutoYGR2", d = 1.27, svc = "GarudaReboundService", ev = "Activated", mv = "Garuda Rebound" },
        },
        risingstar = { { f = "AutoYRR", d = .2, png = true, ys = 2 } },
        massbreaker = { { f = "AutoYMB", d = .2, png = true, ys = 1 } },
        garudastab = { { f = "AutoYGS", d = .2, png = true, ys = 1 } },
    };

    local function fireys(n, f)
        for i = 1, n do
            if i > 1 then
                task.wait(.5);
                if opt(f, false) ~= true then return; end;
            end;
            ac.firesvc("YukiService", "RightActivated", nil);
            task.wait(.1);
            if opt(f, false) ~= true then return; end;
            ac.firesvc("YukiService", "RightDeactivated");
        end;
    end;

    local down = Vector3.new(0, -50, 0);
    local rprm = RaycastParams.new();
    rprm.FilterType = Enum.RaycastFilterType.Exclude;
    local rfil = { nil, nil };

    local function airwait(tgt, f)
        local hum = ut.alive(tgt);
        local th = hum and ut.hrp(tgt);
        if not th then return false; end;
        local lo = num("GojoAirMin", 7);
        local hi = lo + num("GojoAirBand", 3);
        local t0 = os.clock();
        while os.clock() - t0 < 5 do
            if opt(f, false) ~= true or not (th.Parent and hum.Health > 0) then return false; end;
            rfil[1], rfil[2] = tgt, s.lp.Character;
            rprm.FilterDescendantsInstances = rfil;
            local p = th.Position;
            local r = workspace:Raycast(p, down, rprm);
            if r then
                local h = p.Y - r.Position.Y;
                if h >= lo and h <= hi then return true; end;
            end;
            task.wait(.05);
        end;
        return false;
    end;

    local function nearwait(tgt, f, rf)
        local hum = ut.alive(tgt);
        local th = hum and ut.hrp(tgt);
        local h = ut.hrp(s.lp.Character);
        if not (th and h) then return false; end;
        local r = num(rf, 10);
        local rsq, t0 = r * r, os.clock();
        while os.clock() - t0 < 5 do
            if opt(f, false) ~= true or not (th.Parent and hum.Health > 0) then return false; end;
            if not h.Parent then
                h = ut.hrp(s.lp.Character);
                if not h then return false; end;
            end;
            if ut.dist2sq(th.Position, h.Position) <= rsq then return true; end;
            task.wait(.05);
        end;
        return false;
    end;

    function ms.autofollow(v)
        if v and ctx.block then ctx.block.start(); end;
    end;

    local function runfup(c, nid)
        if opt(c.f, false) ~= true then return; end;
        if c.p then
            local set = fl.idpaths[nid];
            if not (set and set[c.p]) then return; end;
        end;
        task.spawn(function()
            local t = (c.air or c.near or c.tgt or c.arc) and ((lk and lk.tgt) or (bf and bf.closest())) or nil;
            if c.air then
                if not (t and airwait(t, c.f)) then return; end;
            elseif c.near then
                if not (t and nearwait(t, c.f, c.near)) then return; end;
            elseif c.d or c.dk then
                local w = c.dk and num(c.dk, c.d or 0) or c.d;
                if c.png then w = math.max(0, w - (tk and tk.sping() or 0) / 1000); end;
                if w > 0 then task.wait(w); end;
                if opt(c.f, false) ~= true then return; end;
            end;
            if c.arc then
                if t and bf then bf.arcdash(t); end;
                return;
            end;
            if c.ys then fireys(c.ys, c.f); return; end;
            if c.noarg then ac.firesvc(c.svc, c.ev, nil); return; end;
            if not c.mv then ac.firesvc(c.svc, c.ev, t); return; end;
            local ch = s.lp.Character;
            local mvf = ch and ch:FindFirstChild("Moveset");
            local m = mvf and mvf:FindFirstChild(c.mv);
            if m then ac.firesvc(c.svc, c.ev, m, c.tgt and t or nil); end;
        end);
    end;

    function ms.onselfanim(nid)
        local n = fl.name(nid);
        local l = n and fups[n];
        if not l then return; end;
        for _, c in l do runfup(c, nid); end;
    end;

    local efx = {
        PressingChargesService = {
            { f = "AutoHig4", k = "Startup", dk = "AutoHig4Delay", d = .8, svc = "ExtendSwingService", ev = "Activated", mv = "Extended Swings" },
            { f = "AutoHig42", k = "Startup", dk = "AutoHig42Delay", d = .8, svc = "JusticeServedService", ev = "Activated", mv = "Justice Served" },
        },
    };

    local function efxhook()
        for sname, list in efx do
            local svc = s.knit:FindFirstChild(sname);
            local re = svc and svc:FindFirstChild("RE");
            local ev = re and re:FindFirstChild("Effects");
            if ev then
                ut.add(ev.OnClientEvent:Connect(function(kind, who)
                    if who ~= s.lp.Character then return; end;
                    for _, c in list do
                        if c.k == kind then runfup(c, nil); end;
                    end;
                end));
            end;
        end;
    end;
    efxhook();

    local hdb = 0;

    function ms.ondodge(char, hrp, nid)
        if opt("HarutaDodge", false) ~= true then return; end;
        local ch = s.lp.Character;
        if not ch or ch:GetAttribute("Moveset") ~= "Haruta" then return; end;
        local sa = ch:FindFirstChild("SetAssets");
        if sa and sa:FindFirstChild("HarutaSword") then return; end;
        local bkm = ctx.block;
        
        
        
        
        
        local ab = (bkm and bkm.en) or opt("AutoCounter", false) == true;
        if ab and (fl.flags(nid) or fl.blockable(nid)) then return; end;
        local now = os.clock();
        if now - hdb < .4 then return; end;
        local h = ut.hrp(ch);
        if not h then return; end;
        local r = num("HarutaDodgeDist", 20);
        if ut.dist2sq(h.Position, hrp.Position) > r * r then return; end;
        
        
        if bkm and (bkm.blocking or bkm.selfblocking()) then return; end;
        hdb = now;
        s.blockon:FireServer(nil);
        task.delay(num("HarutaDodgeHold", .4), function()
            if bkm and bkm.blocking then return; end;
            s.blockoff:FireServer();
        end);
    end;

    local hgcon, hgqte, hgchoose, hgbusy, hgtok = {}, nil, nil, false, 0;
    local hgseen = ut.weak();
    local hgbtns = { "Silence", "Confess", "Denial" };

    local function fireclick(b)
        for _, c in getconnections(b.MouseButton1Down) do c:Fire(); end;
    end;

    local function qterun(g)
        hgtok += 1;
        local my = hgtok;
        task.spawn(function()
            local d = num("HiguDelay", 0);
            if d > 0 then task.wait(d); end;
            local t0 = os.clock();
            while my == hgtok and g.Parent and os.clock() - t0 < 30 do
                if opt("AutoHiguQTE", false) ~= true then break; end;
                local ch = s.lp.Character;
                if ch then
                    local miss = math.random(100) <= num("HiguMiss", 0);
                    for _, c in ch:GetChildren() do
                        if c:IsA("RemoteEvent") then
                            if miss then pcall(c.FireServer, c); else pcall(c.FireServer, c, true); end;
                        end;
                    end;
                end;
                task.wait(.05);
            end;
        end);
    end;

    local function dochoose()
        if hgbusy or opt("AutoHiguDomain", false) ~= true then return; end;
        local g = hgchoose;
        if not (g and g.Parent) then return; end;
        local pick = opt("HiguChoice", "Silence");
        if pick == "Random" then pick = hgbtns[math.random(3)]; end;
        local b = g:FindFirstChild(pick);
        if not (b and b.Visible) then return; end;
        hgbusy = true;
        pcall(function()
            local d = num("HiguDelay", 0);
            if d > 0 then task.wait(d); end;
            if not (g and g.Parent) then return; end;
            if math.random(100) <= num("HiguMiss", 0) then
                local wrong = {};
                for _, n in hgbtns do if n ~= pick then wrong[#wrong + 1] = n; end; end;
                local wb = g:FindFirstChild(wrong[math.random(#wrong)]);
                if wb and wb.Visible then fireclick(wb); end;
                return;
            end;
            b = g:FindFirstChild(pick);
            if b and b.Visible then fireclick(b); end;
        end);
        hgbusy = false;
    end;

    local function hgwatch(gui, fn)
        for _, d in gui:GetDescendants() do
            if d:IsA("GuiObject") and not hgseen[d] then
                hgseen[d] = true;
                hgcon[#hgcon + 1] = d:GetPropertyChangedSignal("Visible"):Connect(fn);
                if d:IsA("TextLabel") or d:IsA("TextButton") then
                    hgcon[#hgcon + 1] = d:GetPropertyChangedSignal("Text"):Connect(fn);
                end;
            end;
        end;
        hgcon[#hgcon + 1] = gui.DescendantAdded:Connect(function(d)
            if not d:IsA("GuiObject") or hgseen[d] then return; end;
            hgseen[d] = true;
            if #hgcon > 512 then ut.compact(hgcon); end;
            hgcon[#hgcon + 1] = d:GetPropertyChangedSignal("Visible"):Connect(fn);
            task.defer(fn);
        end);
        task.defer(fn);
    end;

    function ms.higu(v)
        if not v then
            if opt("AutoHiguQTE", false) == true or opt("AutoHiguDomain", false) == true then return; end;
            hgtok += 1;
            for _, c in hgcon do pcall(function() c:Disconnect(); end); end;
            table.clear(hgcon);
            table.clear(hgseen);
            hgqte, hgchoose = nil, nil;
            return;
        end;
        local pg = s.lp:FindFirstChildWhichIsA("PlayerGui");
        if not pg then return; end;
        if opt("AutoHiguQTE", false) == true then
            local q = pg:FindFirstChild("QTE");
            if q then hgqte = q; qterun(q); end;
        end;
        if #hgcon > 0 then return; end;
        local function add(g)
            if g.Name == "QTE" then
                hgqte = g;
                qterun(g);
            elseif g.Name == "Choose" then
                hgchoose = g;
                hgwatch(g, dochoose);
            end;
        end;
        hgcon[#hgcon + 1] = pg.ChildAdded:Connect(add);
        for _, g in pg:GetChildren() do add(g); end;
    end;

    local wsconn, wshum = nil, nil;

    function ms.ws(v)
        if not v then
            if wsconn then wsconn:Disconnect(); wsconn = nil; end;
            wshum = nil;
            return;
        end;
        if wsconn then return; end;
        wsconn = s.runs.Heartbeat:Connect(function()
            if not (wshum and wshum.Parent and wshum.Health > 0) then
                wshum = ut.alive(s.lp.Character);
                if not wshum then return; end;
            end;
            local sp = num("WSVal", 16);
            if wshum.WalkSpeed ~= sp then wshum.WalkSpeed = sp; end;
        end);
    end;

    local arconn, arhum, arhrp, arnt = nil, nil, nil, 0;

    function ms.autoroll(v)
        if not v then
            if arconn then arconn:Disconnect(); arconn = nil; end;
            arhum, arhrp = nil, nil;
            return;
        end;
        if arconn then return; end;
        
        
        
        
        
        
        arconn = s.runs.Heartbeat:Connect(function()
            local now = os.clock();
            if now < arnt then return; end;
            arnt = now + .05;
            if not (arhrp and arhrp.Parent and arhum and arhum.Parent and arhum.Health > 0) then
                local ch = s.lp.Character;
                arhum = ut.alive(ch);
                arhrp = arhum and ut.hrp(ch);
                if not arhrp then return; end;
            end;
            if arhum:GetState() ~= Enum.HumanoidStateType.Freefall then return; end;
            if arhrp.AssemblyLinearVelocity.Y > -50 then return; end;
            local ch = arhrp.Parent;
            if ch:GetAttribute("Movement") then return; end;
            local inf = ch:FindFirstChild("Info");
            if inf and (inf:FindFirstChild("InSkill") or inf:FindFirstChild("Block")
                or inf:FindFirstChild("Stun") or inf:FindFirstChild("NoParkour")) then return; end;
            arjump = now;
            
            arhum.Jump = false;
            arhum.Jump = true;
        end);
    end;

    local emconn = nil;

    function ms.emoteslot(v)
        if emconn then emconn:Disconnect(); emconn = nil; end;
        local function apply()
            local g = s.lp:FindFirstChild("Gamepasses");
            if not g then return; end;
            g:SetAttribute("742180133", v == true);
            g:SetAttribute("1151174294", v == true);
        end;
        apply();
        if not v then return; end;
        emconn = s.lp.ChildAdded:Connect(function(c)
            if c.Name == "Gamepasses" then task.defer(apply); end;
        end);
    end;

    function ms.items()
        local f = workspace:FindFirstChild("Items");
        local out = {};
        if not f then return { "None" }; end;
        for _, i in f:GetChildren() do
            if i:IsA("BasePart") and i:FindFirstChild("ProximityPrompt") and i.CFrame.Y < 1000 then out[#out + 1] = i.Name; end;
        end;
        if #out == 0 then out[1] = "None"; end;
        table.sort(out);
        return out;
    end;

    function ms.grab(name)
        if not name or name == "None" or typeof(fireproximityprompt) ~= "function" then return false; end;
        local f = workspace:FindFirstChild("Items");
        local itm = f and f:FindFirstChild(name);
        local pp = itm and itm:FindFirstChild("ProximityPrompt");
        local hrp = ut.hrp(s.lp.Character);
        if not (pp and hrp) then return false; end;
        local acs = s.knit:FindFirstChild("AntiCheatService");
        local re = acs and acs:FindFirstChild("RE");
        local cam = re and re:FindFirstChild("Camera");
        if cam then cam.Parent = nil; end;
        task.spawn(function()
            for _ = 1, 2 do
                if not (itm.Parent and hrp.Parent) then break; end;
                hrp.CFrame = itm.CFrame;
                pcall(fireproximityprompt, pp, pp.HoldDuration);
                task.wait(.3);
            end;
            if cam then cam.Parent = re; end;
        end);
        return true;
    end;

    local hbr, hbhook = nil, false;

    function ms.hitbox(v)
        if v and not hbhook then
            hbhook = true;
            local p = s.lp:FindFirstChild("PlayerScripts");
            p = p and p:FindFirstChild("Controllers");
            p = p and p:FindFirstChild("Combat");
            p = p and p:FindFirstChild("HitboxController");
            local ok, c = pcall(require, p);
            if not (ok and type(c) == "table" and type(c.SphereHitbox) == "function") then return; end;
            local od = c.SphereHitbox;
            c.SphereHitbox = function(self, ch, cf, r)
                return od(self, ch, cf, hbr or r);
            end;
        end;
        hbr = v and num("HitboxSize", 20) or nil;
    end;

    local tchook, aimon, deacton = false, false, false;

    local function abiltgt()
        local t = lk and lk.tgt;
        if t and t.Parent and ut.alive(t) then return t; end;
        return bf and bf.closest(num("AbilAimRange", 100)) or nil;
    end;

    local function hooktc()
        if tchook then return true; end;
        local p = s.lp:FindFirstChild("PlayerScripts");
        p = p and p:FindFirstChild("Controllers");
        p = p and p:FindFirstChild("Character");
        p = p and p:FindFirstChild("ToolController");
        local ok, c = pcall(require, p);
        if not (ok and type(c) == "table") then return false; end;
        tchook = true;
        local ogt = c.GetTarget;
        if type(ogt) == "function" then
            c.GetTarget = function(self)
                if aimon then
                    local t = abiltgt();
                    if t then return t; end;
                end;
                return ogt(self);
            end;
        end;
        local ogp = c.GetTargetOrProjectile;
        if type(ogp) == "function" then
            c.GetTargetOrProjectile = function(self)
                if aimon then
                    local t = abiltgt();
                    if t then return t; end;
                end;
                return ogp(self);
            end;
        end;
        local out = c.UseTool;
        if type(out) == "function" then
            c.UseTool = function(self, tool, action)
                if deacton and action == "Activated" then
                    task.delay(num("AbilDeacDelay", .5), function()
                        if deacton then pcall(out, self, tool, "Deactivated"); end;
                    end);
                end;
                return out(self, tool, action);
            end;
        end;
        return true;
    end;

    ms.abilok = function()
        local p = s.lp:FindFirstChild("PlayerScripts");
        p = p and p:FindFirstChild("Controllers");
        p = p and p:FindFirstChild("Character");
        return (p and p:FindFirstChild("ToolController")) ~= nil;
    end;

    function ms.abilaim(v)
        aimon = v == true;
        if aimon then return hooktc(); end;
        return true;
    end;

    function ms.abildeac(v)
        deacton = v == true;
        if deacton then return hooktc(); end;
        return true;
    end;

    function ms.hitboxsize(v)
        if hbr then hbr = tonumber(v) or hbr; end;
    end;

    local tdconn, tdeff, tdact, tdright, tdswdb, tdm1db = nil, nil, nil, nil, 0, 0;

    local function todore()
        if tdeff then return true; end;
        local t = s.knit:FindFirstChild("TodoService");
        local re = t and t:FindFirstChild("RE");
        if not re then return false; end;
        tdeff = re:FindFirstChild("Effects");
        tdact = re:FindFirstChild("Activated");
        tdright = re:FindFirstChild("RightActivated");
        return tdeff ~= nil and tdact ~= nil;
    end;

    local function istodo(ch)
        return ch ~= nil and ch:GetAttribute("Moveset") == "Todo";
    end;

    local function sidedir(hrp, thrp)
        local d = ut.flat(thrp.Position - hrp.Position);
        local rv = ut.flat(hrp.CFrame.RightVector);
        return d:Dot(rv) >= 0 and "Right" or "Left";
    end;

    function ms.todo(v)
        if not v then
            if opt("AutoTodoClap", false) ~= true and opt("TodoM1Swap", false) ~= true then
                if tdconn then tdconn:Disconnect(); tdconn = nil; end;
            end;
            return;
        end;
        if tdconn or not todore() then return; end;
        tdconn = tdeff.OnClientEvent:Connect(function(name, atk, tgt)
            if name ~= "Swap" then return; end;
            local ch = s.lp.Character;
            if not istodo(ch) then return; end;
            local mine = atk == ch or tgt == ch;
            if not mine then return; end;
            local m1s = opt("TodoM1Swap", false) == true;
            if not m1s then
                if opt("AutoTodoClap", false) == true then tdact:FireServer(false); end;
                return;
            end;
            local oth = (atk == ch and tgt ~= ch and tgt) or (tgt == ch and atk ~= ch and atk) or nil;
            if not (oth and oth.Parent) then return; end;
            local now = os.clock();
            if now - tdm1db < .35 then return; end;
            tdm1db = now;
            task.spawn(function()
                if not (bf and bf.arcdash(oth)) then
                    local hrp, thrp = ut.hrp(ch), ut.hrp(oth);
                    if not (hrp and thrp) then return; end;
                    ac.dash(ch, sidedir(hrp, thrp));
                end;
                local d = num("TodoM1SwapDelay", 70) * .001;
                if d > 0 then task.wait(d); end;
                if oth.Parent and ch == s.lp.Character then tdact:FireServer(false); end;
            end);
        end);
    end;

    function ms.todoswap2()
        local ch = s.lp.Character;
        if not istodo(ch) or not todore() or not tdright then return; end;
        local now = os.clock();
        if now - tdswdb < num("TodoSwapCD", .2) then return; end;
        local hrp = ut.hrp(ch);
        if not hrp then return; end;
        local md = num("TodoSwapDist", 60);
        local p, msq = hrp.Position, md * md;
        local a, b, ad, bd = nil, nil, math.huge, math.huge;
        for _, c in ut.chars() do
            if c ~= ch and ut.alive(c) then
                local th = ut.hrp(c);
                if th then
                    local d = ut.dist2sq(p, th.Position);
                    if d <= msq then
                        if d < ad then a, b, ad, bd = c, a, d, ad;
                        elseif d < bd then b, bd = c, d; end;
                    end;
                end;
            end;
        end;
        if not a then return; end;
        tdswdb = now;
        tdright:FireServer(a);
        if not b then return; end;
        task.delay(.06, function()
            if s.lp.Character == ch and istodo(ch) and b.Parent then tdright:FireServer(b); end;
        end);
    end;

    local rhconn = nil;

    function ms.todorhit(v)
        if not v then
            if rhconn then rhconn:Disconnect(); rhconn = nil; end;
            return;
        end;
        if rhconn or not todore() or not tdright then return; end;
        local pb = s.knit:FindFirstChild("PebbleThrowService");
        local re = pb and pb:FindFirstChild("RE");
        local ef = re and re:FindFirstChild("Effects");
        if not ef then return; end;
        rhconn = ef.OnClientEvent:Connect(function(kind, char)
            if kind ~= "Hit" or char == s.lp.Character or not istodo(s.lp.Character) then return; end;
            task.wait(.15);
            if rhconn and char.Parent then tdright:FireServer(char); end;
        end);
    end;

    local nrconn, nreff, nrright = nil, nil, nil;

    function ms.autoratio(v)
        if not v then
            if nrconn then nrconn:Disconnect(); nrconn = nil; end;
            return;
        end;
        if nrconn then return; end;
        if not nreff then
            local n = s.knit:FindFirstChild("NanamiService");
            local re = n and n:FindFirstChild("RE");
            nreff = re and re:FindFirstChild("Effects");
            nrright = re and re:FindFirstChild("RightActivated");
        end;
        if not (nreff and nrright) then return; end;
        nrconn = nreff.OnClientEvent:Connect(function(a, who, tgt, _, _, dur, st)
            if a ~= "SpawnRatio" or who ~= s.lp then return; end;
            local w = (tonumber(dur) or 0) * num("RatioTiming", 0.7) - (workspace:GetServerTimeNow() - (tonumber(st) or 0));
            if w > 0 then task.wait(w); end;
            if nrconn then nrright:FireServer(tgt); end;
        end);
    end;

    local idconn, idfn = nil, nil;

    local function dashfn()
        if not idfn then
            local mc = s.movectrl;
            idfn = mc and type(mc.DashRequest) == "function" and mc.DashRequest or nil;
        end;
        return idfn;
    end;

    function ms.infdash(v)
        if not v then
            if idconn then idconn:Disconnect(); idconn = nil; end;
            if idfn then pcall(debug.setupvalue, idfn, 4, tick()); end;
            return;
        end;
        if idconn then return; end;
        local f = dashfn();
        if not f or typeof(debug.setupvalue) ~= "function" then
            ut.warn("infdash", "no dash controller");
            return;
        end;
        if not pcall(debug.setupvalue, f, 4, 0) then idfn = nil; return; end;
        local gu = typeof(debug.getupvalue) == "function" and debug.getupvalue or nil;
        idconn = s.runs.Heartbeat:Connect(gu and function()
            if gu(f, 4) ~= 0 then debug.setupvalue(f, 4, 0); end;
            if gu(f, 6) ~= 2 then debug.setupvalue(f, 6, 2); end;
        end or function()
            debug.setupvalue(f, 4, 0);
            debug.setupvalue(f, 6, 2);
        end);
    end;

    local iadd, irem, ichar, bshb, bshum = nil, nil, nil, nil, nil;
    local astun, nbs = false, false;

    local function bsstop()
        if bshb then bshb:Disconnect(); bshb = nil; end;
        bshum = nil;
    end;

    local function bsstart()
        if bshb or not nbs then return; end;
        bshb = s.runs.Heartbeat:Connect(function()
            if not (bshum and bshum.Parent and bshum.Health > 0) then
                bshum = ut.alive(s.lp.Character);
                if not bshum then bsstop(); return; end;
            end;
            local sp = num("BlockSpeed", 16);
            if bshum.WalkSpeed ~= sp then bshum.WalkSpeed = sp; end;
            if bshum.JumpPower ~= 50 then bshum.JumpPower = 50; end;
        end);
    end;

    local function infdrop()
        if iadd then iadd:Disconnect(); iadd = nil; end;
        if irem then irem:Disconnect(); irem = nil; end;
        bsstop();
    end;

    local function infhook(ch)
        infdrop();
        local inf = ch and (ch:FindFirstChild("Info") or ch:WaitForChild("Info", 5));
        if not inf then return; end;
        if astun then
            local st = inf:FindFirstChild("Stun");
            if st then st:Destroy(); end;
        end;
        if nbs and inf:FindFirstChild("Block") then bsstart(); end;
        iadd = inf.ChildAdded:Connect(function(c)
            local n = c.Name;
            if n == "Stun" then
                if astun then task.defer(c.Destroy, c); end;
            elseif n == "Block" and nbs then
                bsstart();
            end;
        end);
        irem = inf.ChildRemoved:Connect(function(c)
            if c.Name == "Block" then bsstop(); end;
        end);
    end;

    local function infsync()
        if not (astun or nbs) then
            if ichar then ichar:Disconnect(); ichar = nil; end;
            infdrop();
            return;
        end;
        if not ichar then ichar = s.lp.CharacterAdded:Connect(function(ch) task.defer(infhook, ch); end); end;
        task.spawn(infhook, s.lp.Character);
    end;

    function ms.antistun(v)
        astun = v == true;
        infsync();
    end;

    function ms.noblockslow(v)
        nbs = v == true;
        infsync();
    end;

    local hopping = false;
    local hitt, mconns, tpchar, tpanim, tpbusy, warming = {}, {}, nil, nil, false, false;
    local mnames, hitkw = { "Function", "Event" }, { "hitbox", "launch", "blackflash", "dmg", "damage" };

    local function ishit(n, v)
        if n ~= "Function" and n ~= "Event" then return false; end;
        v = tostring(v):lower();
        for _, k in hitkw do
            if v:find(k, 1, true) then return true; end;
        end;
        return false;
    end;

    local function scan(id)
        local ok, seq = pcall(s.kfp.GetKeyframeSequenceAsync, s.kfp, id);
        if not ok or not seq then return nil; end;
        local ts = {};
        for _, kf in seq:GetKeyframes() do
            local ok2, ml = pcall(kf.GetMarkers, kf);
            if ok2 then
                for _, m in ml do
                    if ishit(m.Name, m.Value) then
                        ts[#ts + 1] = kf.Time;
                        break;
                    end;
                end;
            end;
        end;
        if #ts == 0 then return false; end;
        table.sort(ts);
        return ts;
    end;

    local function warm(id)
        if hitt[id] ~= nil then return; end;
        hitt[id] = false;
        task.spawn(function()
            local r = scan(id);
            if r ~= nil then hitt[id] = r; end;
        end);
    end;

    local function prewarm()
        if warming then return; end;
        local ch = s.lp.Character;
        local mv = ch and ch:GetAttribute("Moveset");
        local fld = mv and s.animfld:FindFirstChild(mv);
        if not fld then return; end;
        warming = true;
        task.spawn(function()
            for _, d in fld:GetDescendants() do
                if not tpchar then break; end;
                local id = d:IsA("Animation") and d.AnimationId;
                if id and id ~= "" and hitt[id] == nil then
                    hitt[id] = false;
                    local r = scan(id);
                    if r ~= nil then hitt[id] = r; end;
                    task.wait(0.03);
                end;
            end;
            warming = false;
        end);
    end;

    local function tptgt(hrp)
        local t = (lk and lk.tgt) or (bf and bf.target);
        if t and t.Parent and ut.alive(t) and ut.hrp(t) then return t; end;
        local ch = s.lp.Character;
        local r = num("TPARange", 100);
        local best, bd = nil, r * r;
        for _, c in ut.chars() do
            if c ~= ch and ut.alive(c) then
                local h = ut.hrp(c);
                if h then
                    local d = ut.dist2sq(hrp.Position, h.Position);
                    if d < bd then bd, best = d, c; end;
                end;
            end;
        end;
        return best;
    end;

    local pin, pinend, pinback, pintgt = nil, 0, nil, nil;

    local function unpin()
        if pin then pin:Disconnect(); pin = nil; end;
        if pinback and opt("TPAReturn", true) == true then
            local h = ut.hrp(s.lp.Character);
            if h then
                h.CFrame = pinback;
                h.AssemblyLinearVelocity = Vector3.zero;
            end;
        end;
        pinback, pintgt, tpbusy = nil, nil, false;
    end;

    local function tpstep()
        local h = ut.hrp(s.lp.Character);
        local th = pintgt and pintgt.Parent and ut.hrp(pintgt);
        if hopping or not (h and th) or os.clock() >= pinend then unpin(); return; end;
        local tp = th.Position;
        local d = h.Position - tp;
        local away = Vector3.new(d.X, 0, d.Z);
        away = away.Magnitude > 0.01 and away.Unit or -ut.flat(th.CFrame.LookVector);
        local dest = tp + away * num("TPADist", 3);
        h.CFrame = CFrame.new(Vector3.new(dest.X, tp.Y, dest.Z), tp);
        h.AssemblyLinearVelocity = Vector3.zero;
    end;

    local function tpfire()
        if hopping then return; end;
        if tpbusy then
            if pin then pinend = os.clock() + num("TPAHold", 0.2); end;
            return;
        end;
        local hrp = ut.hrp(s.lp.Character);
        local t = hrp and tptgt(hrp);
        if not (t and ut.hrp(t)) then return; end;
        tpbusy, pinback, pintgt = true, hrp.CFrame, t;
        pinend = os.clock() + num("TPAHold", 0.2);
        tpstep();
        pin = s.runs.Heartbeat:Connect(tpstep);
    end;

    local function tpwatch(ch)
        if tpanim then tpanim:Disconnect(); tpanim = nil; end;
        local hum = ch and ch:FindFirstChildOfClass("Humanoid");
        local anm = hum and (hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 5));
        if not anm then return; end;
        tpanim = anm.AnimationPlayed:Connect(function(trk)
            local a = trk.Animation;
            local id = a and a.AnimationId;
            if not id or id == "" then return; end;
            local ht = hitt[id];
            if ht == nil then warm(id); end;
            if ht then
                local lead, now = num("TPALead", 0.06), trk.TimePosition;
                for _, t in ht do
                    local w = t - lead - now;
                    if w > 0 then
                        task.delay(w, function() if trk.IsPlaying then tpfire(); end; end);
                    elseif w > -0.05 then
                        tpfire();
                    end;
                end;
                return;
            end;
            local cs, sc = {}, nil;
            for _, n in mnames do
                local mc;
                mc = trk:GetMarkerReachedSignal(n):Connect(function(v)
                    if ishit(n, v) then tpfire(); end;
                end);
                cs[#cs + 1] = mc;
                mconns[mc] = true;
            end;
            sc = trk.Stopped:Connect(function()
                sc:Disconnect();
                for _, mc in cs do mc:Disconnect(); mconns[mc] = nil; end;
            end);
        end);
        prewarm();
    end;

    function ms.tpattack(v)
        if not v then
            if tpchar then tpchar:Disconnect(); tpchar = nil; end;
            if tpanim then tpanim:Disconnect(); tpanim = nil; end;
            for c in mconns do c:Disconnect(); end;
            table.clear(mconns);
            unpin();
            return;
        end;
        if tpchar then return; end;
        tpchar = s.lp.CharacterAdded:Connect(function(ch) task.defer(tpwatch, ch); end);
        task.spawn(tpwatch, s.lp.Character);
    end;

    local sfchar, sfanim, htchar, htanim = nil, nil, nil, nil;

    local function hoptgt(hrp, r)
        local ch, p = s.lp.Character, hrp.Position;
        local best, bd = nil, r * r;
        for _, c in ut.chars() do
            if c ~= ch and ut.alive(c) then
                local h = ut.hrp(c);
                if h then
                    local dx, dz = p.X - h.Position.X, p.Z - h.Position.Z;
                    local d = dx * dx + dz * dz;
                    if d < bd and p.Y - h.Position.Y < 3 then bd, best = d, c; end;
                end;
            end;
        end;
        return best;
    end;

    local function m1mode(hum, ch)
        local air = hum.FloorMaterial == Enum.Material.Air;
        if ch:GetAttribute("Moveset") == "Hanami" then return hum.Jump and "Up" or air and "Down" or false; end;
        return air and "Down" or hum.Jump and "Up" or false;
    end;

    local function hop(ch, hum, hrp, tgt, stk, tap)
        hopping = true;
        task.spawn(function()
            task.wait(0.1);
            local th = ut.hrp(tgt);
            if not (hrp.Parent and th and th.Parent) then hopping = false; return; end;
            local ps, pt = hrp.Position, th.Position + Vector3.new(0, 5.8, 0);
            local bp = Instance.new("BodyPosition");
            bp.MaxForce = Vector3.new(1e5, 1e5, 1e5);
            bp.P, bp.D, bp.Position = 25000, 400, ps;
            bp.Parent = hrp;
            hum.Jump = true;
            hum:ChangeState(Enum.HumanoidStateType.Jumping);
            for i = 0, 10 do
                if not (hrp.Parent and th.Parent) then break; end;
                local t = i * 0.1;
                bp.Position = Vector3.new(ps.X + (pt.X - ps.X) * t, ps.Y + (pt.Y - ps.Y) * t + 26 * t * (1 - t), ps.Z + (pt.Z - ps.Z) * t);
                task.wait(0.03);
            end;
            local rate, nxt = tap and num("HTRate", 0.05) or 0, 0;
            local t0 = os.clock();
            while os.clock() - t0 < stk and hrp.Parent and th.Parent do
                bp.Position = th.Position + Vector3.new(0, 5.8, 0);
                if tap and os.clock() >= nxt then
                    nxt = os.clock() + rate;
                    ac.m1(m1mode(hum, ch), tgt);
                end;
                task.wait(0.03);
            end;
            bp:Destroy();
            hrp.AssemblyLinearVelocity = Vector3.zero;
            hopping = false;
        end);
    end;

    local function hopwatch(ch, ids, nm, rflag, rdef, sflag, sdef, tap)
        local hum = ut.alive(ch);
        local anm = hum and (hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 5));
        if not anm then return nil; end;
        local fl = ctx.filter;
        return anm.AnimationPlayed:Connect(function(trk)
            if hopping or not fl then return; end;
            local a = trk.Animation;
            if trk.Name ~= nm and not (a and fl[ids][fl.normid(a.AnimationId)]) then return; end;
            local hrp = ut.hrp(s.lp.Character);
            local t = hrp and hoptgt(hrp, num(rflag, rdef));
            if t then hop(ch, hum, hrp, t, num(sflag, sdef), tap); end;
        end);
    end;

    local function sfwatch(ch)
        if sfanim then sfanim:Disconnect(); end;
        sfanim = hopwatch(ch, "upids", "Up", "SurfRange", 5, "SurfStick", 0.3, false);
    end;

    function ms.surf(v)
        if not v then
            if sfchar then sfchar:Disconnect(); sfchar = nil; end;
            if sfanim then sfanim:Disconnect(); sfanim = nil; end;
            return;
        end;
        if sfchar then return; end;
        sfchar = s.lp.CharacterAdded:Connect(function(ch) task.defer(sfwatch, ch); end);
        task.spawn(sfwatch, s.lp.Character);
    end;

    local function htwatch(ch)
        if htanim then htanim:Disconnect(); end;
        htanim = hopwatch(ch, "melids", nil, "HTRange", 6, "HTStick", 0.6, true);
    end;

    function ms.headtap(v)
        if not v then
            if htchar then htchar:Disconnect(); htchar = nil; end;
            if htanim then htanim:Disconnect(); htanim = nil; end;
            return;
        end;
        if htchar then return; end;
        htchar = s.lp.CharacterAdded:Connect(function(ch) task.defer(htwatch, ch); end);
        task.spawn(htwatch, s.lp.Character);
    end;

    local m1mode, m1rem, m1sync, m1fn, m1old = nil, nil, nil, nil, nil;

    local function findrem()
        local mv = ac.moveset() or s.lp:GetAttribute("Moveset");
        local svc = mv and s.knit:FindFirstChild(mv .. "Service");
        local re = svc and svc:FindFirstChild("RE");
        m1rem = re and re:FindFirstChild("Activated") or nil;
    end;

    function ms.lastm1(mode)
        m1mode = mode;
        if not mode then
            if m1fn and pcall(hookmetamethod, game, "__namecall", m1old) then m1fn, m1old = nil, nil; end;
            return;
        end;
        findrem();
        if not m1sync then
            m1sync = s.lp:GetAttributeChangedSignal("Moveset"):Connect(findrem);
            ut.add(m1sync);
            ut.add(s.lp.CharacterAdded:Connect(function() task.defer(findrem); end));
        end;
        if m1fn then return; end;
        if not (hookmetamethod and getnamecallmethod and checkcaller and newcclosure) then m1mode = nil; return; end;
        m1fn = newcclosure(function(self, ...)
            if m1mode and self == m1rem and (...) == false and getnamecallmethod() == "FireServer" and not checkcaller() then
                return m1old(self, m1mode);
            end;
            return m1old(self, ...);
        end);
        m1old = hookmetamethod(game, "__namecall", m1fn);
    end;

    local lookcd = 0;

    function ms.onlook(char, hrp, nid)
        local now = os.clock();
        if now < lookcd or not fl.blockable(nid) then return; end;
        local h = ut.hrp(s.lp.Character);
        if not h then return; end;
        local d = h.Position - hrp.Position;
        local f = Vector3.new(d.X, 0, d.Z);
        if f.Magnitude < 0.01 then return; end;
        f = f.Unit;
        local lv = ut.flat(hrp.CFrame.LookVector);
        if lv:Dot(f) < math.cos(math.rad(num("TPLookAngle", 45))) then return; end;
        if char ~= ((lk and lk.tgt) or (bf and bf.closest())) then return; end;
        lookcd = now + num("TPLookCD", 0.5);
        local tp, dist = hrp.Position, num("TPLookDist", 3);
        local dest = opt("TPLookBehind", true) == true and tp - lv * dist or tp + f * dist;
        h.CFrame = CFrame.new(Vector3.new(dest.X, tp.Y, dest.Z), tp);
        h.AssemblyLinearVelocity = Vector3.zero;
    end;

    function ms.tplook(v)
        if v and ctx.block then ctx.block.start(); end;
    end;

    local orconn, ortgt, orang, orhrp, orhum, orthrp, orthum = nil, nil, 0, nil, nil, nil, nil;

    local function mousetgt()
        local ch = s.lp.Character;
        local mp = s.uis:GetMouseLocation();
        local best, bd = nil, math.huge;
        for _, c in ut.chars() do
            if c ~= ch and ut.alive(c) then
                local h = ut.hrp(c);
                if h then
                    local sp, vis = s.cam:WorldToViewportPoint(h.Position);
                    if vis then
                        local dx, dy = sp.X - mp.X, sp.Y - mp.Y;
                        local d = dx * dx + dy * dy;
                        if d < bd then bd, best = d, c; end;
                    end;
                end;
            end;
        end;
        return best;
    end;

    function ms.orbit(v)
        if not v then
            if orconn then orconn:Disconnect(); orconn = nil; end;
            if orhum and orhum.Parent then orhum.AutoRotate = true; end;
            ortgt, orhrp, orhum, orthrp, orthum = nil, nil, nil, nil, nil;
            return;
        end;
        if orconn then return; end;
        ortgt = opt("OrbitMode", "Mouse") == "Nearest" and bf and bf.autotgt() or mousetgt();
        if not ortgt then return; end;
        local ch = s.lp.Character;
        orhum = ut.alive(ch);
        orhrp = orhum and ut.hrp(ch);
        orthum = ut.alive(ortgt);
        orthrp = orthum and ut.hrp(ortgt);
        if not (orhrp and orthrp) then ms.orbit(false); return; end;
        orhum.AutoRotate = false;
        local p, tp = orhrp.Position, orthrp.Position;
        orang = math.atan2(p.Z - tp.Z, p.X - tp.X);
        orconn = s.runs.Heartbeat:Connect(function(dt)
            if not (orhrp.Parent and orhum.Health > 0) then
                local c = s.lp.Character;
                orhum = ut.alive(c);
                orhrp = orhum and ut.hrp(c);
                if not orhrp then ms.orbit(false); return; end;
                orhum.AutoRotate = false;
            end;
            if not (orthrp.Parent and orthum.Health > 0) then ms.orbit(false); return; end;
            orang += math.rad(num("OrbitSpeed", 180)) * dt;
            local t, r = orthrp.Position, num("OrbitRange", 8);
            orhrp.AssemblyLinearVelocity = Vector3.zero;
            orhrp.CFrame = CFrame.new(Vector3.new(t.X + math.cos(orang) * r, t.Y, t.Z + math.sin(orang) * r), t);
        end);
    end;

    

    local dmwas, dmconns, dmbox, dmon = ut.weak(), {}, nil, false;

    local function dmpart(p)
        if dmwas[p] ~= nil or not p:IsA("BasePart") then return; end;
        dmwas[p] = p.CanCollide;
        pcall(function() p.CanCollide = false; end);
    end;

    local function dmbind(box)
        if not box or dmbox == box then return; end;
        dmbox = box;
        for _, d in box:GetDescendants() do dmpart(d); end;
        dmconns[#dmconns + 1] = box.DescendantAdded:Connect(function(d)
            if dmon then dmpart(d); end;
        end);
    end;

    function ms.domwalk(v)
        if v ~= true then
            if not dmon then return; end;
            dmon = false;
            ut.drop(dmconns);
            dmbox = nil;
            for p, was in dmwas do
                if p.Parent then pcall(function() p.CanCollide = was; end); end;
            end;
            table.clear(dmwas);
            return;
        end;
        if dmon then return; end;
        dmon = true;
        dmconns[#dmconns + 1] = workspace.ChildAdded:Connect(function(c)
            if dmon and c.Name == "Domains" then dmbind(c); end;
        end);
        dmbind(workspace:FindFirstChild("Domains"));
    end;

    function ms.unload()
        ms.domwalk(false);
        ms.orbit(false);
        ms.infjump(false);
        ms.antistun(false);
        ms.noblockslow(false);
        ms.infdash(false);
        ms.autoratio(false);
        ms.hitbox(false);
        ms.todorhit(false);
        ms.ws(false);
        ms.autoroll(false);
        ms.emoteslot(false);
        if tdconn then tdconn:Disconnect(); tdconn = nil; end;
        for _, c in hgcon do pcall(function() c:Disconnect(); end); end;
        table.clear(hgcon);
        ms.tpattack(false);
        ms.surf(false);
        ms.headtap(false);
        ms.lastm1(nil);
    end;

    ut.add({ Disconnect = ms.unload });
    return ms;
end;

end)();
local _M15 = (function()
return function(ctx)
    local s, ut = ctx.svc, ctx.ut;
    local mb = { map = {}, acts = {}, short = {}, actcat = {}, groups = {} };
    local gui, btns, cns = nil, {}, {};
    local pos, size, lock, tok, red = {}, 60, false, 0, false;
    local skip = { MobileBtns = true, MobileLock = true, MobileDrops = true, MobileList = true };

    local function dir()
        local l = ctx.lib;
        return l and l.dir;
    end;

    local function load()
        if red then return; end;
        red = true;
        local d = dir();
        if not (d and isfile and readfile) then return; end;
        local p = d .. "/mobile.json";
        local ok, has = pcall(isfile, p);
        if not (ok and has) then return; end;
        local ok2, raw = pcall(readfile, p);
        if not (ok2 and type(raw) == "string" and raw ~= "") then return; end;
        local ok3, dt = pcall(function() return s.http:JSONDecode(raw); end);
        if ok3 and type(dt) == "table" and type(dt.pos) == "table" then pos = dt.pos; end;
    end;

    local function save()
        local d = dir();
        if not (d and writefile) then return; end;
        tok += 1;
        local my = tok;
        task.delay(.25, function()
            if my ~= tok then return; end;
            if isfolder and makefolder then
                local ok, has = pcall(isfolder, d);
                if ok and not has then pcall(makefolder, d); end;
            end;
            local ok, txt = pcall(function() return s.http:JSONEncode({ pos = pos }); end);
            if ok then pcall(writefile, d .. "/mobile.json", txt); end;
        end);
    end;

    
    
    
    local tabof, nameof, tabt = {}, {}, 0;

    local function reindex()
        local l = ctx.lib;
        if not (l and type(l.Index) == "function") then return; end;
        local now = os.clock();
        if now - tabt <= 5 then return; end;
        tabt = now;
        table.clear(tabof);
        table.clear(nameof);
        local ok, idx = pcall(l.Index, l);
        if not ok then return; end;
        for _, e in next, idx do
            local fl = e.it and e.it.f;
            if fl then
                if e.tab and e.tab.name then tabof[fl] = e.tab.name; end;
                
                
                if e.it.nm then nameof[fl] = e.it.nm; end;
            end;
        end;
    end;

    function mb.tab(f)
        reindex();
        return tabof[f];
    end;

    function mb.name(f)
        reindex();
        return nameof[f];
    end;

    function mb.vals()
        local l = ctx.lib;
        local v = {};
        table.clear(mb.map);
        table.clear(mb.short);
        
        
        
        table.clear(mb.groups);
        if not l then return v; end;
        local drops = ctx.opt("MobileDrops", true) == true;

        local function want(o, f)
            if type(o) ~= "table" or skip[f] then return false; end;
            if o.t == "toggle" then return (o.name or mb.name(f)) ~= nil; end;
            
            if not (drops and o.t == "dropdown" and not o.multi) then return false; end;
            return mb.name(f) ~= nil;
        end;

        local seen, dup = {}, {};
        for f, o in next, l.opts do
            if want(o, f) then
                local nm = o.name or mb.name(f);
                if seen[nm] then dup[nm] = true; end;
                seen[nm] = true;
            end;
        end;
        for f, o in next, l.opts do
            if want(o, f) then
                local nm = o.name or mb.name(f);
                local n = dup[nm] and (nm .. " (" .. f .. ")") or nm;
                mb.map[n] = f;
                mb.short[n] = n;
                mb.groups[n] = mb.tab(f);
                v[#v + 1] = n;
            end;
        end;
        for n in next, mb.acts do
            mb.short[n] = n;
            mb.groups[n] = mb.actcat[n];
            v[#v + 1] = n;
        end;
        table.sort(v);
        return v;
    end;

    local function paint(one, v)
        local th = ctx.lib.theme;
        if one.act then
            one.b.BackgroundColor3 = th.elem;
            one.t.TextColor3 = th.txt;
            return;
        end;
        local o = one.o;
        
        
        if o and o.t == "dropdown" then
            if v == nil then v = o.v; end;
            one.t.Text = one.short .. "\n" .. tostring(v);
            one.b.BackgroundColor3 = th.elem;
            one.t.TextColor3 = th.txt;
            return;
        end;
        if v == nil then v = o and o.v or false; end;
        one.b.BackgroundColor3 = v and th.acc or th.elem;
        one.t.TextColor3 = v and th.on or th.dim;
    end;

    local function mk(n, short)
        local th = ctx.lib.theme;
        local b = Instance.new("TextButton");
        b.AutoButtonColor = false;
        b.BorderSizePixel = 0;
        b.Text = "";
        b.BackgroundColor3 = th.elem;
        b.BackgroundTransparency = .1;
        b.Size = UDim2.fromOffset(size, size);
        b.Parent = gui;
        local c = Instance.new("UICorner");
        c.CornerRadius = UDim.new(0, 12);
        c.Parent = b;
        local k = Instance.new("UIStroke");
        k.Color = th.line;
        k.Thickness = 1;
        k.Parent = b;
        local t = Instance.new("TextLabel");
        t.BackgroundTransparency = 1;
        t.Size = UDim2.new(1, -10, 1, -10);
        t.Position = UDim2.fromOffset(5, 5);
        t.TextScaled = true;
        t.Font = Enum.Font.GothamBold;
        t.TextColor3 = th.dim;
        
        
        t.Text = short or n;
        t.Parent = b;
        local cs = Instance.new("UITextSizeConstraint");
        cs.MaxTextSize = 14;
        cs.Parent = t;
        return { b = b, t = t, n = n, short = short or n };
    end;

    local function layout()
        local gap = 8;
        for i, one in btns do
            one.b.Size = UDim2.fromOffset(size, size);
            local p = pos[one.n];
            if p then
                one.b.Position = UDim2.new(p.x, p.ox, p.y, p.oy);
            else
                local c, r = (i - 1) % 2, math.floor((i - 1) / 2);
                one.b.Position = UDim2.new(.5, -30 + c * (size + gap), .5, -30 + r * (size + gap));
            end;
        end;
    end;

    local function wire()
        local cur, st, bs, tch, pin, d0, s0, dirty = nil, nil, nil, {}, false, nil, nil, false;
        for _, one in btns do
            cns[#cns + 1] = one.b.Activated:Connect(function()
                if one.act then one.act(); return; end;
                local o = one.o;
                if not o then return; end;
                if o.t == "dropdown" then
                    
                    local vl = o.vals or {};
                    if #vl == 0 then return; end;
                    local at = 0;
                    for k, vv in vl do if vv == o.v then at = k; break; end; end;
                    o:Set(vl[at % #vl + 1]);
                    return;
                end;
                o:Set(not o.v);
            end);
            cns[#cns + 1] = one.b.InputBegan:Connect(function(i)
                if lock then return; end;
                local u = i.UserInputType;
                if u ~= Enum.UserInputType.Touch and u ~= Enum.UserInputType.MouseButton1 then return; end;
                local p = one.b.Position;
                cur, st = one, i.Position;
                bs = { x = p.X.Scale, ox = p.X.Offset, y = p.Y.Scale, oy = p.Y.Offset };
            end);
        end;
        cns[#cns + 1] = s.uis.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch then tch[i] = true; end;
        end);
        cns[#cns + 1] = s.uis.InputChanged:Connect(function(i)
            if lock then return; end;
            if i.UserInputType == Enum.UserInputType.Touch then
                local a, b2, n = nil, nil, 0;
                for k in tch do
                    n += 1;
                    if n == 1 then a = k; elseif n == 2 then b2 = k; break; end;
                end;
                if n >= 2 then
                    cur, pin = nil, true;
                    local d = (a.Position - b2.Position).Magnitude;
                    if not d0 then d0, s0 = d, size; end;
                    size = math.clamp(s0 * (d / math.max(d0, 1)), 30, 200);
                    local so = ctx.lib.opts.MobileSize;
                    if so then so:Set(size, true); end;
                    dirty = true;
                    layout();
                    return;
                end;
            end;
            if pin or not (cur and st and bs) then return; end;
            local dv = i.Position - st;
            local ox, oy = bs.ox + dv.X, bs.oy + dv.Y;
            cur.b.Position = UDim2.new(bs.x, ox, bs.y, oy);
            pos[cur.n] = { x = bs.x, ox = ox, y = bs.y, oy = oy };
            dirty = true;
        end);
        cns[#cns + 1] = s.uis.InputEnded:Connect(function(i)
            local u = i.UserInputType;
            if u == Enum.UserInputType.Touch then
                tch[i] = nil;
                local n = 0;
                for _ in tch do n += 1; end;
                if n < 2 then pin, d0 = false, nil; end;
                if n > 0 then return; end;
                cur = nil;
            elseif u == Enum.UserInputType.MouseButton1 then
                cur, pin, d0 = nil, false, nil;
            else
                return;
            end;
            if dirty then
                dirty = false;
                save();
            end;
        end);
    end;

    function mb.start()
        if gui then return; end;
        local l = ctx.lib;
        if not l then return; end;
        load();
        mb.vals();
        size = math.clamp(ctx.opt("MobileSize", 60), 30, 200);
        local sel, raw = {}, l.flags and l.flags.MobileList;
        if type(raw) == "table" then
            for n, on in next, raw do
                if on and (mb.acts[n] or mb.map[n]) then sel[#sel + 1] = n; end;
            end;
        end;
        if #sel == 0 then return; end;
        table.sort(sel);
        gui = Instance.new("ScreenGui");
        gui.Name = "mbt";
        gui.DisplayOrder = 999;
        gui.ResetOnSpawn = false;
        gui.IgnoreGuiInset = true;
        gui.Parent = gethui and gethui() or game:GetService("CoreGui");
        for i, n in sel do
            local one = mk(n, mb.short[n]);
            one.act = mb.acts[n] or mb.acts[mb.short[n] or n];
            one.o = not one.act and l.opts[mb.map[n]] or nil;
            if one.o then
                one.old = one.o.cb;
                one.o.cb = function(v)
                    paint(one, v);
                    if one.old then one.old(v); end;
                end;
            end;
            paint(one);
            btns[i] = one;
        end;
        layout();
        wire();
    end;

    function mb.stop()
        ut.drop(cns);
        for _, one in btns do
            if one.o then one.o.cb = one.old; end;
        end;
        table.clear(btns);
        if gui then
            gui:Destroy();
            gui = nil;
        end;
    end;

    function mb.on(v)
        if v then mb.start(); else mb.stop(); end;
    end;

    function mb.sync()
        if not gui and ctx.opt("MobileBtns", false) ~= true then return; end;
        mb.stop();
        mb.start();
    end;

    function mb.setlock(v)
        lock = v == true;
    end;

    function mb.setsize(n)
        size = math.clamp(tonumber(n) or 60, 30, 200);
        if gui then layout(); end;
    end;

    return mb;
end;

end)();
local _M16 = (function()
return function(ctx)
    local s, ut, opt = ctx.svc, ctx.ut, ctx.opt;
    local ac, bf, lk, bk, fl = ctx.act, ctx.bfc, ctx.lock, ctx.block, ctx.filter;
    local cb = { on = false, tgt = nil, last = nil };
    local tok = 0;

    local digits = { ["1"] = "One", ["2"] = "Two", ["3"] = "Three", ["4"] = "Four", ["5"] = "Five" };

    local function keycode(n)
        n = tostring(n or ""):lower();
        local d = digits[n];
        if d then return Enum.KeyCode[d]; end;
        local ok, kc = pcall(function() return Enum.KeyCode[n:sub(1, 1):upper() .. n:sub(2)]; end);
        return ok and kc or nil;
    end;

    local sti = setthreadidentity or setidentity;

    local function ident()
        if sti then pcall(sti, 8); end;
    end;

    local function tapkey(n, hold)
        local kc = keycode(n);
        if not kc then return false; end;
        ident();
        s.vim:SendKeyEvent(true, kc, false, game);
        task.wait(tonumber(hold) or .03);
        s.vim:SendKeyEvent(false, kc, false, game);
        return true;
    end;

    local function click(btn, hold)
        ident();
        s.vim:SendMouseButtonEvent(0, 0, btn, true, game, 1);
        task.wait(tonumber(hold) or .02);
        s.vim:SendMouseButtonEvent(0, 0, btn, false, game, 1);
    end;

    local function animator(c)
        local h = c and c:FindFirstChildOfClass("Humanoid");
        return h and h:FindFirstChildOfClass("Animator");
    end;

    local function playing(c, test)
        local a = animator(c);
        if not a then return false; end;
        for _, tr in ut.tracks(a) do
            local an = tr.Animation;
            if an and test(fl.normid(an.AnimationId)) then return true; end;
        end;
        return false;
    end;

    local ACTMIN = Enum.AnimationPriority.Action.Value;
    local CORE = Enum.AnimationPriority.Core.Value;

    local function acting(c)
        local a = animator(c);
        if not a then return false; end;
        for _, tr in ut.tracks(a) do
            local pv = tr.Priority.Value;
            if tr.IsPlaying and pv >= ACTMIN and pv ~= CORE then return true; end;
        end;
        return false;
    end;

    function cb.target()
        local t = cb.tgt;
        if t and t.Parent and ut.alive(t) then return t; end;
        cb.tgt = nil;
        return (lk and lk.tgt) or (bf and bf.closest());
    end;

    local function named(n)
        n = tostring(n or ""):lower();
        for _, c in ut.chars() do
            if c.Name:lower() == n then return c; end;
        end;
        return nil;
    end;

    local function selected(flag)
        local nm = opt(flag, "None");
        if nm == "None" then return nil; end;
        return named(nm);
    end;

    local unsupported = { inult = true, needburst = true, whiffed = true };
    cb.unsupported = unsupported;

    local function cond1(c, who)
        if not who then return false; end;
        if c == "dead" then return ut.alive(who) == nil; end;
        if c == "ragdolled" then return (who:GetAttribute("Ragdoll") or 0) > 0; end;
        if c == "stunned" then return bf and bf.stunned(who) == true; end;
        if c == "blocking" then return playing(who, fl.selfblock); end;
        if c == "notblocking" then return not playing(who, fl.selfblock); end;
        if c == "hitanim" then return playing(who, function(n) return fl.hitids[n] == true; end); end;
        if c == "lowhp" then
            local h = ut.alive(who);
            return h ~= nil and h.MaxHealth > 0 and (h.Health / h.MaxHealth) <= (tonumber(opt("ComboLowHP", 30)) or 30) / 100;
        end;
        if c == "thirdparty" then
            local hrp = ut.hrp(s.lp.Character);
            local t = cb.target();
            if not hrp then return false; end;
            local r = tonumber(opt("ComboThirdDist", 40)) or 40;
            for _, o in ut.chars() do
                if o ~= s.lp.Character and o ~= t and ut.alive(o) then
                    local oh = ut.hrp(o);
                    if oh and ut.dist2sq(hrp.Position, oh.Position) <= r * r then return true; end;
                end;
            end;
            return false;
        end;
        return false;
    end;

    function cb.cond(c)
        c = tostring(c or ""):lower();
        if c == "" then return false; end;
        local en = c:match("^(.-)enemy$");
        if en and en ~= "" then return cond1(en, cb.target()); end;
        if unsupported[c] then return false; end;
        return cond1(c, s.lp.Character);
    end;

    local function waitanim(my, to)
        local t0 = os.clock();
        while os.clock() - t0 < .25 do
            if my ~= tok then return; end;
            if acting(s.lp.Character) then break; end;
            task.wait();
        end;
        t0 = os.clock();
        while my == tok and os.clock() - t0 < (to or 3) do
            if not acting(s.lp.Character) then return; end;
            task.wait();
        end;
    end;

    local function waithit(my, to)
        local t = cb.target();
        local t0 = os.clock();
        while my == tok and os.clock() - t0 < (tonumber(to) or 2) do
            if t and t.Parent and playing(t, function(n) return fl.hitids[n] == true; end) then return true; end;
            task.wait(.03);
        end;
        return false;
    end;

    local function aimdir(d, deg)
        local cam = s.cam;
        if not cam then return; end;
        deg = math.rad(tonumber(deg) or 35);
        local cf = cam.CFrame;
        local lv = cf.LookVector;
        local yaw = math.atan2(-lv.X, -lv.Z);
        local pitch = math.asin(math.clamp(lv.Y, -1, 1));
        if d == "up" then pitch = deg;
        elseif d == "down" then pitch = -deg;
        elseif d == "left" then yaw += deg;
        elseif d == "right" then yaw -= deg;
        elseif d == "level" then pitch = 0;
        else return; end;
        cam.CFrame = CFrame.new(cf.Position) * CFrame.fromEulerAnglesYXZ(pitch, yaw, 0);
    end;

    local dashmap = { front = "Front", back = "Back", left = "Left", right = "Right" };

    local function dashdir(d)
        local ch = s.lp.Character;
        if not ch then return; end;
        ac.dash(ch, dashmap[tostring(d or ""):lower()] or "Front");
    end;

    local function sidedash(d)
        local ch = s.lp.Character;
        local hrp = ut.hrp(ch);
        if not hrp then return; end;
        d = tostring(d or ""):lower();
        if d == "left" then d = "Left";
        elseif d == "right" then d = "Right";
        else
            local t = cb.target();
            local th = t and ut.hrp(t);
            if th then
                d = ut.flat(th.Position - hrp.Position):Dot(ut.flat(hrp.CFrame.RightVector)) >= 0 and "Right" or "Left";
            else
                d = "Right";
            end;
        end;
        ac.dash(ch, d);
    end;

    
    
    local wrp = RaycastParams.new();
    wrp.FilterType = Enum.RaycastFilterType.Exclude;
    local wfil = {};

    local function facewall(r)
        local ch = s.lp.Character;
        local hrp = ut.hrp(ch);
        local cam = s.cam;
        if not (hrp and cam) then return; end;
        r = tonumber(r) or 60;
        table.clear(wfil);
        for _, c in ut.chars() do wfil[#wfil + 1] = c; end;
        wrp.FilterDescendantsInstances = wfil;
        local p = hrp.Position;
        local best, bd = nil, r;
        for i = 0, 23 do
            local a = math.rad(i * 15);
            local hit = workspace:Raycast(p, Vector3.new(math.sin(a), 0, math.cos(a)) * r, wrp);
            if hit then
                local d = (hit.Position - p).Magnitude;
                if d < bd then bd, best = d, hit.Position; end;
            end;
        end;
        if not best then return; end;
        local cp = cam.CFrame.Position;
        cam.CFrame = CFrame.lookAt(cp, Vector3.new(best.X, cp.Y, best.Z));
    end;

    local function setlock(t)
        if not t then return false; end;
        cb.tgt = t;
        lk.hold(true);
        lk.start(t);
        return true;
    end;

    
    local function exec(ln, my, marks)
        local a;

        a = ln:match("^wait%s+([%d%.]+)$");
        if a then task.wait(tonumber(a) or 0); return; end;

        if ln == "waitforanimend" or ln == "waitforattackanim" then waitanim(my); return; end;

        a = ln:match("^waithit%s*([%d%.]*)$");
        if a then waithit(my, a ~= "" and a or nil); return; end;

        if ln == "m1" then click(0); return; end;
        if ln == "m2" then click(1); return; end;
        if ln == "block" then s.blockon:FireServer(nil); return; end;
        if ln == "unblock" then s.blockoff:FireServer(); return; end;

        local ad, av = ln:match("^aim%s+(%a+)%s*([%d%.]*)$");
        if ad then aimdir(ad, av ~= "" and av or nil); return; end;

        a = ln:match("^sidedash%s*(%a*)$");
        if a then sidedash(a); return; end;

        a = ln:match("^dash%s*(%a*)$");
        if a then dashdir(a); return; end;

        a = ln:match("^facewall%s*([%d%.]*)$");
        if a then facewall(a ~= "" and a or nil); return; end;

        local k, h = ln:match("^key%s+([%a%d_]+)%s*([%d%.]*)$");
        if not k then k, h = ln:match("^press%s+([%a%d_]+)%s*([%d%.]*)$"); end;
        if k then tapkey(k, h ~= "" and h or nil); return; end;

        if ln == "bfc" or ln:match("^bfc%s") then
            if bf then bf.manual(); end;
            local d = tonumber(ln:match("^bfc%s+([%d%.]+)"));
            if ln:find("waitforanimend") then waitanim(my); elseif d then task.wait(d); end;
            return;
        end;

        if ln == "unlock" then
            cb.tgt = nil;
            lk.hold(false);
            if opt("LockOn", false) ~= true and opt("LockBlock", false) ~= true then lk.stop(); end;
            return;
        end;
        if ln == "lockselected" then setlock(selected("ABTarget")); return; end;
        a = ln:match("^lockclosest%s*([%d%.]*)$");
        if a then setlock(bf and bf.closest(a ~= "" and tonumber(a) or nil)); return; end;

        a = ln:match("^settarget%s+(.+)$");
        if a then
            local t;
            if a == "closest" then t = bf and bf.closest();
            elseif a == "selected" or a == "abselected" then t = selected("ABTarget");
            elseif a == "sdaselected" then t = selected("SDATarget");
            elseif a == "lock" then t = lk and lk.tgt;
            else t = named(a); end;
            if t then cb.tgt = t; end;
            return;
        end;

        a = ln:match("^checkchar%s+(.+)$");
        if a then
            local mv = ac.moveset();
            if not mv or mv:lower() ~= a then return "stop"; end;
            return;
        end;

        a = ln:match("^stopif%s+([%a%d_]+)$") or ln:match("^if%s+([%a%d_]+)%s+then%s+stop$");
        if a then
            if cb.cond(a) then return "stop"; end;
            return;
        end;

        local c, sub = ln:match("^if%s+([%a%d_]+)%s+then%s+(.+)$");
        if c then
            if cb.cond(c) then return exec(sub, my, marks); end;
            return;
        end;

        if ln == "loopstart" then return; end;

        local lc, lsub = ln:match("^loopuntil%s+([%a%d_]+)%s+then%s+(.+)$");
        if not lc then lc = ln:match("^loopuntil%s+([%a%d_]+)$"); end;
        if lc then
            if cb.cond(lc) then
                if lsub then return exec(lsub, my, marks); end;
                return;
            end;
            return marks.loop;
        end;

        return;
    end;

    

    local skconn = nil;

    local function skstep()
        if not cb.on then cb.stick(false); return; end;
        local hrp = ut.hrp(s.lp.Character);
        local t = cb.target();
        local th = t and t.Parent and ut.hrp(t);
        if not (hrp and th) then return; end;
        local tp = th.Position;
        local off = hrp.Position - tp;
        local flat = Vector3.new(off.X, 0, off.Z);
        local fm = flat.Magnitude;
        local d = tonumber(opt("ComboStickDist", 4)) or 4;
        if fm <= d + 1 and math.abs(off.Y) <= 4 then return; end;
        local away = fm > .01 and (flat / fm) or -ut.flat(th.CFrame.LookVector);
        local dest = tp + away * d;
        local goal = CFrame.new(Vector3.new(dest.X, tp.Y, dest.Z), tp);
        local a = math.clamp((tonumber(opt("ComboStickSmooth", 25)) or 25) / 100, .05, 1);
        hrp.CFrame = hrp.CFrame:Lerp(goal, a);
    end;

    function cb.stick(v)
        if skconn then skconn:Disconnect(); skconn = nil; end;
        if v ~= true then return; end;
        skconn = s.runs.Heartbeat:Connect(skstep);
    end;

    function cb.stop()
        cb.stick(false);
        tok += 1;
        cb.on = false;
        cb.tgt = nil;
        if lk then
            lk.hold(false);
            if opt("LockOn", false) ~= true and opt("LockBlock", false) ~= true then lk.stop(); end;
        end;
    end;

    function cb.play(text)
        text = text or opt("ComboScript", "");
        if type(text) ~= "string" or not text:match("%S") then return false; end;
        cb.stop();
        tok += 1;
        local my = tok;
        cb.on = true;
        if opt("ComboStick", false) == true then cb.stick(true); end;
        task.spawn(function()
            ident();
            local lines = {};
            for ln in (text .. "\n"):gmatch("(.-)\r?\n") do
                ln = ln:lower():gsub("^%s+", ""):gsub("%s+$", "");
                if ln ~= "" and not ln:match("^%-%-") and ln ~= "{" and ln ~= "}" then
                    lines[#lines + 1] = ln;
                end;
            end;
            local marks = { loop = 1 };
            local i, guard = 1, 0;
            while i <= #lines and my == tok do
                guard += 1;
                if guard > 4000 then break; end;
                local ln = lines[i];
                if ln == "loopstart" then marks.loop = i + 1; end;
                local ok, r = pcall(exec, ln, my, marks);
                if not ok then
                    ut.warn("combo", "line " .. i .. ": " .. tostring(r));
                elseif r == "stop" then
                    break;
                elseif type(r) == "number" then
                    i = r;
                    continue;
                end;
                i += 1;
            end;
            if my == tok then
                cb.on = false;
                cb.stick(false);
                cb.tgt = nil;
                if lk then
                    lk.hold(false);
                    if opt("LockOn", false) ~= true and opt("LockBlock", false) ~= true then lk.stop(); end;
                end;
            end;
        end);
        return true;
    end;

    local allowed = {
        One = true, Two = true, Three = true, Four = true,
        R = true, Q = true, Space = true,
        W = true, A = true, S = true, D = true,
    };
    local holdk = {
        W = true, A = true, S = true, D = true, Space = true,
        One = true, Two = true, Three = true, Four = true,
    };
    local kout = { One = "1", Two = "2", Three = "3", Four = "4" };

    local rec = { on = false, acts = {}, conns = {}, holds = {}, last = 0 };
    cb.rec = rec;

    function cb.count()
        return #rec.acts;
    end;

    function cb.record(v)
        for _, c in rec.conns do pcall(function() c:Disconnect(); end); end;
        table.clear(rec.conns);
        table.clear(rec.holds);
        if not v then
            rec.on = false;
            return #rec.acts;
        end;
        rec.on = true;
        table.clear(rec.acts);
        rec.last = os.clock();
        local c1 = s.uis.InputBegan:Connect(function(i, gp)
            if gp or not rec.on then return; end;
            local u = i.UserInputType;
            local now = os.clock();
            if u == Enum.UserInputType.Keyboard then
                local n = i.KeyCode.Name;
                if not allowed[n] then return; end;
                rec.acts[#rec.acts + 1] = { t = "k", k = n, d = now - rec.last };
                rec.last = now;
                if holdk[n] then rec.holds[n] = { t = now, i = #rec.acts }; end;
            elseif u == Enum.UserInputType.MouseButton1 then
                rec.acts[#rec.acts + 1] = { t = "m1", d = now - rec.last };
                rec.last = now;
            elseif u == Enum.UserInputType.MouseButton2 then
                rec.acts[#rec.acts + 1] = { t = "m2", d = now - rec.last };
                rec.last = now;
            end;
        end);
        local c2 = s.uis.InputEnded:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.Keyboard then return; end;
            local n = i.KeyCode.Name;
            local h = rec.holds[n];
            if not h then return; end;
            local e = rec.acts[h.i];
            if e then e.h = os.clock() - h.t; end;
            rec.holds[n] = nil;
        end);
        rec.conns[1], rec.conns[2] = c1, c2;
        ut.add(c1);
        ut.add(c2);
        return 0;
    end;

    
    
    function cb.toscript()
        local o = {};
        for _, a in rec.acts do
            local d = math.floor((a.d or 0) * 100 + .5) / 100;
            if d >= .05 then o[#o + 1] = "wait " .. tostring(d); end;
            if a.t == "m1" or a.t == "m2" then
                o[#o + 1] = a.t;
            elseif a.t == "k" then
                local h = a.h and math.floor(a.h * 100 + .5) / 100 or 0;
                o[#o + 1] = "key " .. (kout[a.k] or a.k):lower() .. (h >= .05 and (" " .. tostring(h)) or "");
            end;
        end;
        return table.concat(o, "\n");
    end;

    

    cb.presets = {
        {
            name = "Naoya Wall",
            flag = "Naoya",
            char = "naoya",
            text = [[checkchar naoya
lockclosest 30
m1
waitforanimend
m1
waitforanimend
m1
waitforanimend
m1
waitforanimend
aim up 40
key 4
waitforanimend
m1
waitforanimend
m1
waitforanimend
m1
waitforanimend
facewall 60
key 1
waitforanimend
sidedash
m1
waitforanimend
key r
waitforanimend
key 3
waitforanimend
key 3
waitforanimend
m1
waitforanimend
m1
waitforanimend
m1
waitforanimend
key 2]],
        },
        {
            name = "Naoya Uplift",
            flag = "NaoyaUplift",
            char = "naoya",
            text = [[checkchar naoya
lockclosest 30
m1
waitforanimend
m1
waitforanimend
m1
waitforanimend
m1
waitforanimend
key 1
waitforanimend
key 3
waitforanimend
key 3
waitforanimend
key 3
waitforanimend
m1
waitforanimend
m1
waitforanimend
m1
waitforanimend
m1
waitforanimend
key 4
waitforanimend
m1
waitforanimend
m1
waitforanimend
m1
waitforanimend
m1
waitforanimend
dash
key 2]],
        },
    };

    function cb.presetnames()
        local t = table.create(#cb.presets);
        for i, p in cb.presets do t[i] = p.name; end;
        return t;
    end;

    function cb.preset(name)
        for _, p in cb.presets do
            if p.name == name then return p; end;
        end;
        return nil;
    end;

    function cb.playpreset(name)
        local p = cb.preset(name);
        if not p then return false; end;
        return cb.play(p.text);
    end;

    local function dir()
        local l = ctx.lib;
        return l and l.dir and (l.dir .. "/combos") or nil;
    end;

    local function ensure()
        local d = dir();
        if not (d and isfolder and makefolder) then return d; end;
        local ok, has = pcall(isfolder, d);
        if ok and not has then pcall(makefolder, d); end;
        return d;
    end;

    function cb.list()
        local d = dir();
        local v = { "None" };
        if not (d and listfiles) then return v; end;
        local ok, files = pcall(listfiles, d);
        if not ok then return v; end;
        for _, p in next, files do
            local n = tostring(p):match("([^/\\]+)%.txt$");
            if n then v[#v + 1] = n; end;
        end;
        table.sort(v, function(a, b)
            if a == "None" then return true; end;
            if b == "None" then return false; end;
            return a < b;
        end);
        return v;
    end;

    function cb.save(name, text)
        if not (name and name:match("%S") and writefile) then return false; end;
        local d = ensure();
        if not d then return false; end;
        name = name:gsub("[^%w _%-]", "");
        if name == "" then return false; end;
        local ok = pcall(writefile, d .. "/" .. name .. ".txt", text or "");
        return ok, name;
    end;

    function cb.load(name)
        local d = dir();
        if not (d and name and name ~= "None" and isfile and readfile) then return nil; end;
        local p = d .. "/" .. name .. ".txt";
        local ok, has = pcall(isfile, p);
        if not (ok and has) then return nil; end;
        local ok2, txt = pcall(readfile, p);
        return ok2 and txt or nil;
    end;

    function cb.del(name)
        local d = dir();
        if not (d and name and name ~= "None" and delfile) then return false; end;
        return (pcall(delfile, d .. "/" .. name .. ".txt"));
    end;

    return cb;
end;

end)();
local _M17 = (function()
return function(ctx)
    local s, ut, opt = ctx.svc, ctx.ut, ctx.opt;
    local au = {};

    local acls = {
        ParticleEmitter = true, Beam = true, Trail = true,
        PointLight = true, SpotLight = true, SurfaceLight = true,
    };

    local function isaura(d)
        local ch = s.lp.Character;
        local p = d.Parent;
        while p and p ~= ch and p ~= workspace do
            local n = p.Name;
            if n == "Aura" or n == "SetAssets" then return true; end;
            p = p.Parent;
        end;
        return false;
    end;

    
    local clskind = {};
    local function kindof(i)
        local cn = i.ClassName;
        local k = clskind[cn];
        if k ~= nil then return k or nil; end;
        if i:IsA("ParticleEmitter") or i:IsA("Beam") or i:IsA("Trail") then k = "seq";
        elseif i:IsA("Fire") then k = "fire";
        elseif i:IsA("Sparkles") then k = "sparkle";
        elseif i:IsA("Decal") or i:IsA("Texture") then k = "color3";
        elseif i:IsA("SpecialMesh") then k = "vertex";
        elseif i:IsA("BasePart") or i:IsA("Light") or i:IsA("Smoke") then k = "color";
        else k = false; end;
        clskind[cn] = k;
        return k or nil;
    end;

    local kprop = { color = "Color", seq = "Color", fire = "Color", sparkle = "SparkleColor", color3 = "Color3" };
    local WCAP = 300;

    local function grab(d, k)
        if k == "seq" or k == "color" then return d.Color; end;
        if k == "fire" then return d.Color, d.SecondaryColor; end;
        if k == "sparkle" then return d.SparkleColor; end;
        if k == "color3" then return d.Color3; end;
        if k == "vertex" then return d.VertexColor; end;
    end;

    local function put(d, k, a, b)
        if k == "seq" or k == "color" then d.Color = a;
        elseif k == "fire" then d.Color = a; d.SecondaryColor = b or a;
        elseif k == "sparkle" then d.SparkleColor = a;
        elseif k == "color3" then d.Color3 = a;
        elseif k == "vertex" then d.VertexColor = a; end;
    end;

    local function tint(k, c)
        if k == "seq" then return ColorSequence.new(c); end;
        if k == "vertex" then return Vector3.new(c.R, c.G, c.B); end;
        return c;
    end;

    local function mkcolor(pfx, attach)
        local h = { seen = ut.weak(), orig = ut.weak(), ic = ut.weak(), busy = ut.weak(), conns = {}, hue = 0, nw = 0 };

        local function col()
            if opt(pfx .. "Rainbow", false) == true then return Color3.fromHSV(h.hue % 1, 1, 1); end;
            if opt(pfx .. "Grad", false) == true then
                local g = {
                    opt(pfx .. "G1", Color3.fromRGB(255, 0, 0)),
                    opt(pfx .. "G2", Color3.fromRGB(255, 255, 0)),
                    opt(pfx .. "G3", Color3.fromRGB(0, 255, 255)),
                    opt(pfx .. "G4", Color3.fromRGB(255, 0, 255)),
                };
                local t = (h.hue % 1) * 4;
                local i = math.floor(t);
                return g[i % 4 + 1]:Lerp(g[(i + 1) % 4 + 1], t - i);
            end;
            return opt(pfx .. "Color", Color3.fromRGB(0, 200, 255));
        end;
        h.col = col;

        local function apply(d, k, c)
            if h.busy[d] then return; end;
            h.busy[d] = true;
            pcall(put, d, k, tint(k, c), c);
            h.busy[d] = nil;
        end;

        local function drop(d)
            local t = h.ic[d];
            if t then
                for _, c in t do pcall(function() c:Disconnect(); end); end;
                h.ic[d] = nil;
                h.nw -= 1;
            end;
            h.seen[d] = nil;
        end;
        h.drop = drop;

        function h.watch(d)
            if h.seen[d] then return; end;
            local k = kindof(d);
            if not k then return; end;
            h.seen[d] = k;
            if h.orig[d] == nil then
                local ok, a, b = pcall(grab, d, k);
                if ok then h.orig[d] = { k = k, a = a, b = b }; end;
            end;
            apply(d, k, col());
            
            
            local p = kprop[k];
            if not p then return; end;
            if opt(pfx .. "Rainbow", false) == true or opt(pfx .. "Grad", false) == true then return; end;
            if h.nw >= WCAP then
                local n = 0;
                for _ in next, h.ic do n += 1; end;
                h.nw = n;
                if n >= WCAP then return; end;
            end;
            pcall(function()
                local c = d:GetPropertyChangedSignal(p):Connect(function()
                    if h.seen[d] then apply(d, k, col()); end;
                end);
                h.ic[d] = { c };
                h.nw += 1;
            end);
        end;

        function h.repaint()
            local c = col();
            for d, k in next, h.seen do
                if d.Parent then apply(d, k, c); else drop(d); end;
            end;
        end;

        function h.restore()
            for d, o in next, h.orig do
                if d.Parent then pcall(put, d, o.k, o.a, o.b); end;
            end;
            table.clear(h.orig);
        end;

        function h.add(c)
            h.conns[#h.conns + 1] = c;
            ut.add(c);
            return c;
        end;

        function h.set(v)
            for _, c in h.conns do pcall(function() c:Disconnect(); end); end;
            table.clear(h.conns);
            for d in next, h.ic do drop(d); end;
            h.nw = 0;
            if h.loop then h.loop:Disconnect(); h.loop = nil; end;
            table.clear(h.seen);
            if not v then h.restore(); return; end;
            attach(h);
            local acc = 0;
            h.loop = s.runs.Heartbeat:Connect(function(dt)
                if opt(pfx .. "Rainbow", false) ~= true and opt(pfx .. "Grad", false) ~= true then return; end;
                acc += dt;
                if acc < .05 then return; end;
                h.hue += acc * (tonumber(opt(pfx .. "Speed", .4)) or .4) * .25;
                acc = 0;
                h.repaint();
            end);
            ut.add(h.loop);
        end;

        return h;
    end;

    local aura = mkcolor("Aura", function(h)
        local function bind(ch)
            if not ch then return; end;
            for _, d in ch:GetDescendants() do
                if (acls[d.ClassName] or d:IsA("BasePart")) and isaura(d) then h.watch(d); end;
            end;
            h.add(ch.DescendantAdded:Connect(function(d)
                if (acls[d.ClassName] or d:IsA("BasePart")) and isaura(d) then h.watch(d); end;
            end));
            h.add(ch.DescendantRemoving:Connect(h.drop));
        end;
        bind(s.lp.Character);
        h.add(s.lp.CharacterAdded:Connect(function(ch)
            task.wait(.6);
            if opt("AuraOn", false) == true then bind(ch); end;
        end));
    end);

    
    
    local efx = mkcolor("Efx", function(h)
        local root = workspace:FindFirstChild("Effects");
        if not root then return; end;
        for _, d in root:GetDescendants() do h.watch(d); end;
        h.add(root.DescendantAdded:Connect(h.watch));
        h.add(root.DescendantRemoving:Connect(h.drop));
    end);

    au.aura, au.efx = aura, efx;

    local exts = { mp3 = true, ogg = true, wav = true, flac = true, m4a = true, aac = true };
    local files = {};

    local function snddir()
        local l = ctx.lib;
        return l and l.dir and (l.dir .. "/sounds") or nil;
    end;

    function au.sounds()
        local v = { "None" };
        table.clear(files);
        local d = snddir();
        if not (d and listfiles) then return v; end;
        if isfolder and makefolder then
            local ok, has = pcall(isfolder, d);
            if ok and not has then pcall(makefolder, d); end;
        end;
        local ok, fs = pcall(listfiles, d);
        if not ok then return v; end;
        for _, p in next, fs do
            local n, e = tostring(p):match("([^/\\]+)%.(%w+)$");
            if n and e and exts[e:lower()] then
                files[n] = p;
                v[#v + 1] = n;
            end;
        end;
        table.sort(v, function(a, b)
            if a == "None" then return true; end;
            if b == "None" then return false; end;
            return a < b;
        end);
        return v;
    end;

    local function asset(n)
        local p = n and n ~= "None" and files[n];
        if not (p and getcustomasset) then return nil; end;
        local ok, a = pcall(getcustomasset, p);
        return ok and a or nil;
    end;

    local function newhook(pfx, attach, match)
        local h = { conns = {}, sc = ut.weak(), tok = ut.weak(), ic = ut.weak(), nw = 0, asset = nil };

        function h.swap(snd)
            if not (h.asset and snd.Parent and opt(pfx .. "On", false) == true) then return; end;
            local st = tonumber(opt(pfx .. "Start", 0)) or 0;
            local cp = tonumber(opt(pfx .. "Clip", 0)) or 0;
            if snd.SoundId ~= h.asset then snd.SoundId = h.asset; end;
            snd.Volume = tonumber(opt(pfx .. "Vol", 1)) or 1;
            snd.Looped = cp <= 0;
            pcall(function()
                snd.TimePosition = st;
                if not snd.IsPlaying then snd:Play(); end;
            end);
            if cp <= 0 then return; end;
            local t = (h.tok[snd] or 0) + 1;
            h.tok[snd] = t;
            task.delay(cp, function()
                if h.tok[snd] ~= t or not snd.Parent then return; end;
                pcall(function() snd:Stop(); snd.TimePosition = st; end);
            end);
        end;

        function h.watch(snd)
            if h.sc[snd] or not snd:IsA("Sound") then return; end;
            if match and not match(snd) then return; end;
            h.sc[snd] = true;
            h.swap(snd);
            if h.nw >= WCAP then
                local n = 0;
                for _ in next, h.ic do n += 1; end;
                h.nw = n;
                if n >= WCAP then return; end;
            end;
            local c1 = snd:GetPropertyChangedSignal("SoundId"):Connect(function() h.swap(snd); end);
            local c2 = snd:GetPropertyChangedSignal("IsPlaying"):Connect(function()
                if snd.IsPlaying then h.swap(snd); end;
            end);
            h.ic[snd] = { c1, c2 };
            h.nw += 1;
        end;

        function h.drop(snd)
            local t = h.ic[snd];
            if t then
                for _, c in t do pcall(function() c:Disconnect(); end); end;
                h.ic[snd] = nil;
                h.nw -= 1;
            end;
            h.sc[snd] = nil;
        end;

        function h.stop()
            for _, c in h.conns do pcall(function() c:Disconnect(); end); end;
            table.clear(h.conns);
            for snd in next, h.ic do h.drop(snd); end;
            h.nw = 0;
            table.clear(h.sc);
        end;

        function h.start()
            h.stop();
            if opt(pfx .. "On", false) ~= true then return; end;
            h.asset = asset(opt(pfx .. "File", "None"));
            if not h.asset then return; end;
            attach(h);
        end;

        function h.reload()
            h.asset = asset(opt(pfx .. "File", "None"));
            if opt(pfx .. "On", false) ~= true then return; end;
            if not h.asset then h.stop(); return; end;
            h.start();
        end;

        function h.apply()
            for snd in next, h.sc do
                if snd.Parent then h.swap(snd); end;
            end;
        end;

        return h;
    end;

    local mus = newhook("Mus", function(h)
        local cur = workspace:FindFirstChild("Music");
        if cur then h.watch(cur); end;
        local c = workspace.ChildAdded:Connect(function(x)
            if x.Name == "Music" and x:IsA("Sound") then h.watch(x); end;
        end);
        h.conns[#h.conns + 1] = c;
        ut.add(c);
    end);

    local bfs = newhook("Bfs", function(h)
        local function hookin(root)
            if not root then return; end;
            for _, d in root:GetDescendants() do h.watch(d); end;
            local c = root.DescendantAdded:Connect(function(d)
                if d:IsA("Sound") then task.defer(h.watch, d); end;
            end);
            h.conns[#h.conns + 1] = c;
            ut.add(c);
            local cr = root.DescendantRemoving:Connect(h.drop);
            h.conns[#h.conns + 1] = cr;
            ut.add(cr);
        end;
        hookin(workspace:FindFirstChild("Effects"));
        hookin(s.lp.Character);
        local ca = s.lp.CharacterAdded:Connect(function(ch)
            task.wait(.6);
            if opt("BfsOn", false) == true then hookin(ch); end;
        end);
        h.conns[#h.conns + 1] = ca;
        ut.add(ca);
    end, function(snd)
        local n = snd.Name:lower();
        return n:find("blackflash", 1, true) ~= nil or n:find("black flash", 1, true) ~= nil;
    end);

    au.mus, au.bfs = mus, bfs;

    function au.stop()
        aura.set(false);
        efx.set(false);
        mus.stop();
        bfs.stop();
    end;

    return au;
end;

end)();
local _M18 = (function()
return function(ctx)
    local s, ut = ctx.svc, ctx.ut;
    local an = {};

    local env = getfenv();
    local RATE, GRACE = 2, 1;

    local function res(p)
        local d = p:find(".", 1, true);
        if not d then return env[p]; end;
        local t = env[p:sub(1, d - 1)];
        return type(t) == "table" and t[p:sub(d + 1)] or nil;
    end;

    local watch = {
        "print", "warn", "error", "setclipboard",
        "rconsoleprint", "rconsolewarn", "rconsoleerr",
        "writefile", "readfile", "appendfile", "delfile",
        "isfile", "isfolder", "listfiles", "makefolder", "getcustomasset",
        "request",
        "hookfunction", "hookmetamethod", "getrawmetatable",
        "loadstring", "getgenv", "getconnections", "firesignal",
    };

    local orig, nc0, idx0, base = {}, nil, nil, 0;

    local function out()
        pcall(function() s.lp:Kick("Lost connection to the game server. (Error Code: 277)"); end);
    end;

    local function meta()
        local ok, mt = pcall(getrawmetatable, game);
        if not (ok and type(mt) == "table") then return nil, nil; end;
        return rawget(mt, "__namecall"), rawget(mt, "__index");
    end;

    function an.count()
        local n = 0;
        for _ in next, orig do n += 1; end;
        return n;
    end;

    function an.rebase()
        table.clear(orig);
        for _, n in watch do
            local f = res(n);
            if type(f) == "function" then orig[n] = f; end;
        end;
        nc0, idx0 = meta();
        base = os.clock();
        return an.count();
    end;

    function an.scan()
        for n, f0 in next, orig do
            if res(n) ~= f0 then return true; end;
        end;
        local nc, ix = meta();
        if nc0 and nc ~= nc0 then return true; end;
        if idx0 and ix ~= idx0 then return true; end;
        return false;
    end;

    
    
    
    
    local taps, tapped, quiet = { "print", "warn", "error", "setclipboard", "rconsoleprint", "rconsolewarn", "rconsoleerr" }, false, false;

    function an.mute(v) quiet = v == true; end;

    local function url(v)
        local t = type(v) == "string" and v or tostring(v);
        if t:find("[jjs][", 1, true) then return false; end;
        return t:find("https://", 1, true) ~= nil or t:find("http://", 1, true) ~= nil;
    end;

    local function tap()
        if tapped then return; end;
        local hf = env.hookfunction or env.replaceclosure;
        local cc = env.checkcaller;
        if type(hf) ~= "function" or type(cc) ~= "function" then return; end;
        tapped = true;
        for _, n in taps do
            local f = env[n];
            if type(f) == "function" then
                pcall(function()
                    local old;
                    old = hf(f, function(...)
                        
                        
                        if cc() and not quiet then
                            for _, a in { ... } do
                                if url(a) then out(); break; end;
                            end;
                        end;
                        return old(...);
                    end);
                end);
            end;
        end;
    end;

    
    
    
    
    
    local gnames = { "HttpGet", "HttpGetAsync", "HttpGetJson", "GetObjects" };

    local function bent(ifh, f)
        if type(f) ~= "function" then return false; end;
        local ok, v = pcall(ifh, f);
        return ok and v == true;
    end;

    local function wired()
        local ifh = env.isfunctionhooked;
        if type(ifh) ~= "function" then return false; end;
        if bent(ifh, res("request")) then return true; end;
        for _, n in gnames do
            if bent(ifh, game[n]) then return true; end;
        end;
        local ok, hs = pcall(game.GetService, game, "HttpService");
        if ok and hs then
            for _, n in { "RequestInternal", "GetAsync", "PostAsync" } do
                local ok2, f = pcall(function() return hs[n]; end);
                if ok2 and bent(ifh, f) then return true; end;
            end;
        end;
        return false;
    end;

    local conn, acc = nil, 0;

    function an.set(v)
        if conn then conn:Disconnect(); conn = nil; end;
        if not v then return; end;
        tap();
        an.rebase();
        if wired() then return out(); end;
        conn = s.runs.Heartbeat:Connect(function(dt)
            acc += dt;
            if acc < RATE then return; end;
            acc = 0;
            if wired() then return out(); end;
            if os.clock() - base < GRACE then return; end;
            if an.scan() then out(); end;
        end);
        ut.add(conn);
    end;

    function an.stop()
        if conn then conn:Disconnect(); conn = nil; end;
        table.clear(orig);
    end;

    return an;
end;

end)();
local _M19 = (function()
return function(ctx)
    local s = ctx.svc;
    local bp = {};
    local env = getfenv();

    local hmm = env.hookmetamethod;
    local ncc = env.newcclosure;
    local gnm = env.getnamecallmethod;
    local cc = env.checkcaller;
    local ga = env.getactors;
    local bufapi;
    pcall(function() bufapi = (type(env.getrenv) == "function" and env.getrenv().buffer) or buffer; end);

    if type(hmm) ~= "function" or type(ncc) ~= "function"
        or type(gnm) ~= "function" or type(cc) ~= "function" then
        bp.ok = false;
        return bp;
    end;
    bp.ok = true;

    local acre = s.knit:FindFirstChild("AntiCheatService");
    acre = acre and acre:FindFirstChild("RE");
    local camrem = acre and acre:FindFirstChild("Camera");
    local tprem = acre and acre:FindFirstChild("Teleport");
    local jre = s.knit:FindFirstChild("JoinService");
    jre = jre and jre:FindFirstChild("RE");
    local rstrem = jre and jre:FindFirstChild("Reset");

    local blocked = {};
    if camrem then blocked[camrem] = true; end;
    if tprem then blocked[tprem] = true; end;
    if rstrem then blocked[rstrem] = true; end;

    local st = { busy = false, active = false, block = false, noclip = false };
    bp.st = st;
    bp.onfinish = nil;

    local function rebase()
        local an = ctx.anti;
        if an and an.rebase then an.rebase(); end;
    end;

    local nc0;
    nc0 = hmm(game, "__namecall", ncc(function(self, ...)
        if not st.busy then return nc0(self, ...); end;
        if cc() then return nc0(self, ...); end;
        local m = gnm();
        if (m == "Kick" or m == "kick") and self == s.lp then return nil; end;
        if m ~= "FireServer" and m ~= "fireServer" then return nc0(self, ...); end;
        if st.block and blocked[self] then return nil; end;
        if st.active and self == camrem and type(bufapi) == "table" then
            local a1, a2 = ...;
            if typeof(a1) == "buffer" and typeof(a2) == "buffer" then
                local spf = bufapi.create(15);
                bufapi.copy(spf, 0, a2, 0, 15);
                return nc0(self, a1, spf, s.lp.Character, 0/0);
            end;
        end;
        return nc0(self, ...);
    end));

    local cfval, idxup, idxo = nil, false, nil;

    local idxhk = ncc(function(self, k, ...)
        if cfval and k == "CFrame" and not cc() then
            local ch = s.lp.Character;
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart");
            if hrp and self == hrp then return cfval; end;
        end;
        return idxo(self, k, ...);
    end);

    local function idxset(v)
        if v == idxup then return; end;
        if v then idxo = hmm(game, "__index", idxhk); else pcall(hmm, game, "__index", idxo); end;
        idxup = v;
        rebase();
    end;

    function bp.spoof(cf)
        cfval = cf;
        idxset(cf ~= nil);
    end;

    local ncconn, ncparts = nil, {};

    local function ncrebuild()
        table.clear(ncparts);
        local ch = s.lp.Character;
        if not ch then return; end;
        for _, v in ch:GetDescendants() do
            if v:IsA("BasePart") then ncparts[#ncparts + 1] = v; end;
        end;
    end;

    local function watch(ch)
        if st._nca then st._nca:Disconnect(); end;
        if st._ncr then st._ncr:Disconnect(); end;
        st._nca = ch.ChildAdded:Connect(ncrebuild);
        st._ncr = ch.ChildRemoved:Connect(ncrebuild);
    end;

    local function ncstart()
        ncrebuild();
        local ch = s.lp.Character;
        if ch then watch(ch); end;
        ncconn = s.runs.Stepped:Connect(function()
            if not st.noclip then return; end;
            for i = 1, #ncparts do
                local v = ncparts[i];
                if v.Parent then v.CanCollide = false; end;
            end;
        end);
    end;

    local function ncstop()
        if ncconn then ncconn:Disconnect(); ncconn = nil; end;
        if st._nca then st._nca:Disconnect(); st._nca = nil; end;
        if st._ncr then st._ncr:Disconnect(); st._ncr = nil; end;
        if st._ca then st._ca:Disconnect(); st._ca = nil; end;
        table.clear(ncparts);
    end;

    local function killactors()
        if type(ga) ~= "function" then return; end;
        pcall(function()
            local lpc, lps = s.lp.Character, s.lp:FindFirstChild("PlayerScripts");
            for _, v in ga() do
                pcall(function()
                    if (lpc and v:IsDescendantOf(lpc)) or (lps and v:IsDescendantOf(lps)) then v:Destroy(); end;
                end);
            end;
        end);
    end;

    local ALIVE, POST = 45, 5;
    local stopovl = nil;

    local function makeovl()
        local sg = Instance.new("ScreenGui");
        sg.Name = "xnhub_acovl";
        sg.IgnoreGuiInset = true;
        sg.DisplayOrder = 999999;
        sg.ResetOnSpawn = false;
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
        local bg = Instance.new("Frame", sg);
        bg.Size = UDim2.new(1, 0, 1, 0);
        bg.BackgroundColor3 = Color3.new(0, 0, 0);
        bg.BorderSizePixel = 0;
        local lbl = Instance.new("TextLabel", bg);
        lbl.Size = UDim2.new(0, 220, 0, 70);
        lbl.Position = UDim2.new(0, 40, 0, 40);
        lbl.BackgroundTransparency = 1;
        lbl.Font = Enum.Font.GothamBold;
        lbl.TextSize = 40;
        lbl.Text = "Xenon Hub";
        lbl.TextColor3 = Color3.fromRGB(120, 90, 255);
        local tmr = Instance.new("TextLabel", bg);
        tmr.Size = UDim2.new(1, 0, 0, 30);
        tmr.Position = UDim2.new(0, 0, 1, -40);
        tmr.BackgroundTransparency = 1;
        tmr.Font = Enum.Font.GothamMedium;
        tmr.TextSize = 18;
        tmr.TextColor3 = Color3.fromRGB(200, 200, 200);
        tmr.Text = "";
        sg.Parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui");
        local cam = workspace.CurrentCamera;
        local vx, vy = 220, 150;
        local hue, t0, last = 0, os.clock(), -1;
        local total = ALIVE + POST;
        local rc = s.runs.RenderStepped:Connect(function(dt)
            local vp = cam and cam.ViewportSize or Vector2.new(1280, 720);
            local px = lbl.Position.X.Offset + vx * dt;
            local py = lbl.Position.Y.Offset + vy * dt;
            local mx = vp.X - lbl.Size.X.Offset;
            local my = vp.Y - lbl.Size.Y.Offset;
            local bounce = false;
            if px <= 0 then px = 0; vx = -vx; bounce = true;
            elseif px >= mx then px = mx; vx = -vx; bounce = true; end;
            if py <= 0 then py = 0; vy = -vy; bounce = true;
            elseif py >= my then py = my; vy = -vy; bounce = true; end;
            lbl.Position = UDim2.new(0, px, 0, py);
            if bounce then
                hue = (hue + .13) % 1;
                lbl.TextColor3 = Color3.fromHSV(hue, .7, 1);
            end;
            local rem = math.ceil(math.max(total - (os.clock() - t0), 0));
            if rem ~= last then
                last = rem;
                tmr.Text = rem .. "s";
            end;
        end);
        return function() rc:Disconnect(); sg:Destroy(); end;
    end;

    function bp.start()
        if st.busy then return false; end;
        st.busy = true;
        st.active = true;
        st.block = true;
        st.noclip = true;
        local ch = s.lp.Character;
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart");
        if hrp then bp.spoof(hrp.CFrame); end;
        killactors();
        ncstart();
        st._ca = s.lp.CharacterAdded:Connect(function(nch)
            if not st.busy then return; end;
            local nhrp = nch:WaitForChild("HumanoidRootPart", 5);
            if not st.busy then return; end;
            ncrebuild();
            watch(nch);
            if nhrp and cfval then bp.spoof(nhrp.CFrame); end;
        end);
        stopovl = makeovl();
        task.spawn(function()
            task.wait(ALIVE);
            if not st.busy then return; end;
            st.block = false;
            if rstrem then pcall(function() rstrem:FireServer(); end); end;
            st.block = true;
            task.wait(POST);
            if not st.busy then return; end;
            bp.finish();
        end);
        return true;
    end;

    function bp.finish()
        st.noclip = false;
        st.active = false;
        st.block = false;
        st.busy = false;
        ncstop();
        bp.spoof(nil);
        if stopovl then pcall(stopovl); stopovl = nil; end;
        if bp.onfinish then pcall(bp.onfinish); end;
    end;

    function bp.stop()
        if not st.busy then return; end;
        bp.finish();
    end;

    function bp.unhook()
        if st.busy then bp.finish(); end;
        idxset(false);
        pcall(hmm, game, "__namecall", nc0);
    end;

    return bp;
end;

end)();
local _M20 = (function()
return function(ctx)
    local s, ut, opt = ctx.svc, ctx.ut, ctx.opt;
    local es = { on = false, n = 0, items = 0, lvl = 0, fps = 0 };

    local env = getfenv();
    local di = env.DrawingImmediate;
    local drw = env.Drawing;

    
    
    
    
    local imm = type(di) == "table" and type(di.GetPaint) == "function";
    local ret = not imm and type(drw) == "table" and type(drw.new) == "function";
    es.ok = imm or ret;
    es.mode = imm and "immediate" or (ret and "retained" or "none");
    if not es.ok then
        function es.set() end;
        function es.sync() end;
        function es.reveal() end;
        function es.stop() end;
        return es;
    end;

    
    
    local Line, OutText, Circle, FillCircle;
    local FONT = imm and (di.Fonts and di.Fonts.UI or 0) or (drw.Fonts and drw.Fonts.UI or 0);
    local sweep, wipe;

    if imm then
        Line, OutText = di.Line, di.OutlinedText;
        Circle, FillCircle = di.Circle, di.FilledCircle;
        sweep = function() end;
        wipe = function() end;
    else
        
        
        
        
        local pool, cur, shadow = {}, {}, {};
        local function grab(kind)
            local p = pool[kind];
            if not p then p = {}; pool[kind] = p; shadow[kind] = {}; end;
            local i = (cur[kind] or 0) + 1;
            cur[kind] = i;
            local o = p[i];
            if not o then
                o = drw.new(kind);
                p[i] = o;
                shadow[kind][i] = {};
            end;
            return o, shadow[kind][i];
        end;

        
        
        
        local function put(o, sh, k, v)
            if sh[k] ~= v then sh[k] = v; o[k] = v; end;
        end;

        sweep = function()
            for kind, p in next, pool do
                local sh = shadow[kind];
                for i = (cur[kind] or 0) + 1, #p do
                    local h = sh[i];
                    if h.Visible ~= false then h.Visible = false; p[i].Visible = false; end;
                end;
                cur[kind] = 0;
            end;
        end;

        wipe = function()
            for _, p in next, pool do
                for _, o in next, p do pcall(function() o:Remove(); end); end;
            end;
            table.clear(pool);
            table.clear(cur);
            table.clear(shadow);
        end;

        Line = function(a, b, c, t, al)
            local o, sh = grab("Line");
            o.From, o.To = a, b;
            put(o, sh, "Color", c);
            put(o, sh, "Thickness", t);
            put(o, sh, "Transparency", al);
            put(o, sh, "Visible", true);
        end;
        Circle = function(pos, r, c, t, sides, al)
            local o, sh = grab("Circle");
            o.Position = pos;
            put(o, sh, "Radius", r);
            put(o, sh, "Color", c);
            put(o, sh, "Thickness", t);
            put(o, sh, "Transparency", al);
            put(o, sh, "NumSides", sides);
            put(o, sh, "Filled", false);
            put(o, sh, "Visible", true);
        end;
        FillCircle = function(pos, r, c, sides, al)
            local o, sh = grab("Circle");
            o.Position = pos;
            put(o, sh, "Radius", r);
            put(o, sh, "Color", c);
            put(o, sh, "Transparency", al);
            put(o, sh, "NumSides", sides);
            put(o, sh, "Filled", true);
            put(o, sh, "Thickness", 1);
            put(o, sh, "Visible", true);
        end;
        OutText = function(pos, font, size, c, al, oc, _, txt, centered)
            local o, sh = grab("Text");
            o.Position = pos;
            put(o, sh, "Font", font);
            put(o, sh, "Size", size);
            put(o, sh, "Color", c);
            put(o, sh, "Transparency", al);
            put(o, sh, "Outline", true);
            put(o, sh, "OutlineColor", oc);
            put(o, sh, "Text", txt);
            put(o, sh, "Center", centered);
            put(o, sh, "Visible", true);
        end;
    end;

    local cam = workspace.CurrentCamera;
    local V2, C3 = Vector2.new, Color3.fromRGB;
    local rad, tan, sqrt, floor, clamp = math.rad, math.tan, math.sqrt, math.floor, math.clamp;

    local function col(f, r, g, b) return opt(f, C3(r, g, b)); end;
    local function num(f, d) return tonumber(opt(f, d)) or d; end;
    local function on(f) return opt(f, false) == true; end;

    
    
    
    local SK15 = {
        p = { "Head", "UpperTorso", "LowerTorso",
            "RightUpperArm", "RightLowerArm", "RightHand",
            "LeftUpperArm", "LeftLowerArm", "LeftHand",
            "RightUpperLeg", "RightLowerLeg", "RightFoot",
            "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" },
        b = { 1,2, 2,3, 2,4, 4,5, 5,6, 2,7, 7,8, 8,9, 3,10, 10,11, 11,12, 3,13, 13,14, 14,15 },
    };
    local SK6 = {
        p = { "Head", "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg" },
        b = { 1,2, 2,3, 2,4, 2,5, 2,6 },
    };

    local CHARMAP = { Itadori = "Yuji" };

    local rec = ut.weak();

    local function trackrec(m)
        local d = rec[m];
        if d then return d; end;
        d = { proj = {}, dist = -1, hp = -1, klast = -1 };
        rec[m] = d;
        return d;
    end;

    local function part(d, m, k, nm)
        local p = d[k];
        if p and p.Parent then return p; end;
        p = m:FindFirstChild(nm);
        d[k] = p;
        return p;
    end;

    local function stunof(d, m)
        if (m:GetAttribute("Ragdoll") or 0) > 0 then return "Ragdoll"; end;
        local inf = d.info;
        if not (inf and inf.Parent) then inf = m:FindFirstChild("Info"); d.info = inf; end;
        if not inf then return nil; end;
        if inf:FindFirstChild("Knockback") then return "Knocked"; end;
        if inf:FindFirstChild("Stun") then return "Stunned"; end;
        return nil;
    end;

    local function chams(d, m, fill, out, ft, ot)
        local h = d.hl;
        if not (h and h.Parent) then
            h = Instance.new("Highlight");
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop;
            h.Adornee = m;
            h.Parent = m;
            d.hl = h;
            d.hf, d.ho, d.hft, d.hot = nil, nil, nil, nil;
        end;
        if d.hf ~= fill then d.hf = fill; h.FillColor = fill; end;
        if d.ho ~= out then d.ho = out; h.OutlineColor = out; end;
        if d.hft ~= ft then d.hft = ft; h.FillTransparency = ft; end;
        if d.hot ~= ot then d.hot = ot; h.OutlineTransparency = ot; end;
    end;

    local function unchams(d)
        local h = d.hl;
        if h then
            if h.Parent then h:Destroy(); end;
            d.hl, d.hf, d.ho = nil, nil, nil;
        end;
    end;

    
    
    

    local LN = { n = 0, a = {}, b = {}, c = {}, t = {} };
    local TX = { n = 0, p = {}, c = {}, s = {}, x = {}, m = {} };
    local CI = { n = 0, p = {}, r = {}, c = {}, t = {}, f = {} };

    local function bufreset()
        LN.n, TX.n, CI.n = 0, 0, 0;
    end;

    local function line(a, b, c, t)
        local i = LN.n + 1; LN.n = i;
        LN.a[i], LN.b[i], LN.c[i], LN.t[i] = a, b, c, t;
    end;
    local function text(p, txt, c, sz, mid)
        local i = TX.n + 1; TX.n = i;
        TX.p[i], TX.x[i], TX.c[i], TX.s[i], TX.m[i] = p, txt, c, sz, mid;
    end;
    local function circ(p, r, c, t, filled)
        local i = CI.n + 1; CI.n = i;
        CI.p[i], CI.r[i], CI.c[i], CI.t[i], CI.f[i] = p, r, c, t, filled;
    end;

    local BLACK = C3(0, 0, 0);

    local function paint()
        local al = 1;
        for i = 1, LN.n do Line(LN.a[i], LN.b[i], LN.c[i], LN.t[i], al); end;
        for i = 1, CI.n do
            local p, r, c, t = CI.p[i], CI.r[i], CI.c[i], CI.t[i];
            if CI.f[i] then FillCircle(p, r, c, 16, al); else Circle(p, r, c, t, 16, al); end;
        end;
        for i = 1, TX.n do
            OutText(TX.p[i], FONT, TX.s[i], TX.c[i], al, BLACK, al, TX.x[i], TX.m[i]);
        end;
        sweep();
    end;

    
    
    

    local F, flagt = {}, 0;

    local function snapflags()
        F.box, F.corner, F.outline = on("EspBox"), on("EspCorner"), on("EspOutline");
        F.skel, F.dot, F.trace = on("EspSkel"), on("EspHeadDot"), on("EspTracer");
        F.cham, F.evade = on("EspChams"), on("EspEvasive");
        F.stun, F.scham = on("EspStun"), on("EspStunChams");
        F.name, F.char, F.dist = on("EspNames"), on("EspChar"), on("EspDistance");
        F.hpt, F.hpb, F.kills = on("EspHealthT"), on("EspHealthBar"), on("EspKills");
        F.lock = on("EspLock");
        F.plr, F.item = on("EspOn"), on("EspItemOn");
        F.auto = opt("EspAuto", true) == true;

        F.maxd = num("EspDist", 1500);
        F.cap = floor(num("EspMax", 12));
        F.thick = num("EspThick", 1);
        F.sz = floor(num("EspTextSize", 14));
        F.dot_r = num("EspDotSize", 4);
        F.lod = num("EspLod", 250);
        F.chamF, F.chamO = num("EspChamsFill", .5), num("EspChamsOut", 0);

        F.base = col("EspColor", 0, 255, 255);
        F.outc = col("EspOutColor", 0, 0, 0);
        F.skc = col("EspSkelColor", 255, 255, 255);
        F.hbc = col("EspHealthColor", 0, 255, 0);
        F.lockc = col("EspLockColor", 255, 50, 50);
        F.chamc = col("EspChamsColor", 0, 255, 255);
        F.stunc = col("EspStunColor", 255, 210, 60);
        F.schamc = col("EspStunChamsColor", 255, 80, 80);
        F.chamoc = col("EspChamsOutColor", 255, 255, 255);

        F.npos, F.cpos = opt("EspNamePos", "Top"), opt("EspCharPos", "Top");
        F.dpos, F.hpos = opt("EspDistPos", "Bottom"), opt("EspHealthPos", "Right");
        F.kpos, F.hside = opt("EspKillPos", "Bottom"), opt("EspHealthSide", "Left");
        F.spos = opt("EspStunPos", "Top");
        F.tfrom = opt("EspTracerFrom", "Bottom");

        F.imaxd = num("EspItemDist", 500);
        F.ibox, F.icorner = on("EspItemBox"), on("EspItemCorner");
        F.iname, F.idist, F.icham = on("EspItemNames"), on("EspItemDistText"), on("EspItemChams");
        F.ic = col("EspItemColor", 255, 200, 60);
    end;

    

    local roster, rn, rdirty = {}, 0, true;
    local iroster, irn, idirty = {}, 0, true;
    local rconns = {};

    local function bindbox(name, mark)
        local box = workspace:FindFirstChild(name);
        if not box then return nil; end;
        rconns[#rconns + 1] = box.ChildAdded:Connect(mark);
        rconns[#rconns + 1] = box.ChildRemoved:Connect(mark);
        return box;
    end;

    local function bindroster()
        for _, c in rconns do pcall(function() c:Disconnect(); end); end;
        table.clear(rconns);
        es.box = bindbox("Characters", function() rdirty = true; end);
        es.ibox = bindbox("Items", function() idirty = true; end);
        for _, c in rconns do ut.add(c); end;
        rdirty, idirty = true, true;
    end;

    local function refresh()
        if rdirty then
            rdirty = false;
            local box = es.box;
            if not (box and box.Parent) then box = workspace:FindFirstChild("Characters"); es.box = box; end;
            local mine = s.lp.Character;
            rn = 0;
            if box then
                for _, m in box:GetChildren() do
                    if m ~= mine and m:IsA("Model") then rn += 1; roster[rn] = m; end;
                end;
            end;
            for i = rn + 1, #roster do roster[i] = nil; end;
        end;
        if idirty then
            idirty = false;
            local box = es.ibox;
            if not (box and box.Parent) then box = workspace:FindFirstChild("Items"); es.ibox = box; end;
            irn = 0;
            if box then
                for _, p in box:GetChildren() do
                    if p:IsA("BasePart") then irn += 1; iroster[irn] = p; end;
                end;
            end;
            for i = irn + 1, #iroster do iroster[i] = nil; end;
        end;
    end;

    

    local rguis, revconns, ron = {}, {}, false;

    local function rclear(m)
        local g = rguis[m];
        if g then
            if g.Parent then g:Destroy(); end;
            rguis[m] = nil;
        end;
    end;

    local function radd(m)
        if not ron or m == s.lp.Character or rguis[m] then return; end;
        local ref = es.revref;
        if not ref then
            local u = game:GetService("ReplicatedStorage"):FindFirstChild("Utils");
            ref = u and u:FindFirstChild("Reveal");
            es.revref = ref;
        end;
        if not ref then return; end;
        local hrp = m:FindFirstChild("HumanoidRootPart");
        if not hrp then return; end;
        local g = ref:Clone();
        g.MaxDistance = num("EspDist", 1500);
        local h = g:FindFirstChild("Handle");
        if h then h.Enabled = true; end;
        g.Parent = hrp;
        rguis[m] = g;
    end;

    function es.reveal(v)
        ron = v == true;
        for _, c in revconns do pcall(function() c:Disconnect(); end); end;
        table.clear(revconns);
        if not ron then
            for m in next, rguis do rclear(m); end;
            return;
        end;
        local box = workspace:FindFirstChild("Characters");
        if not box then ron = false; return; end;
        for _, m in box:GetChildren() do radd(m); end;
        revconns[1] = box.ChildAdded:Connect(function(m) task.wait(.4); radd(m); end);
        revconns[2] = box.ChildRemoved:Connect(rclear);
        ut.add(revconns[1]);
        ut.add(revconns[2]);
    end;

    

    local sT, sB, sL, sR = 0, 0, 0, 0;

    local function label(txt, side, c, x, y, w, h, padL, padR, sz)
        if side == "Top" then
            text(V2(x + w * .5, y - sT - sz), txt, c, sz, true);
            sT += sz + 2;
        elseif side == "Bottom" then
            text(V2(x + w * .5, y + h + sB), txt, c, sz, true);
            sB += sz + 2;
        elseif side == "Left" then
            text(V2(x - 6 - padL - #txt * sz * .55, y + sL), txt, c, sz, false);
            sL += sz + 2;
        else
            text(V2(x + w + 6 + padR, y + sR), txt, c, sz, false);
            sR += sz + 2;
        end;
    end;

    
    
    
    

    local px, py, pz = 0, 0, 0;
    local r00, r01, r02, r10, r11, r12, r20, r21, r22 = 0, 0, 0, 0, 0, 0, 0, 0, 0;
    local hx, hy, foc = 0, 0, 0;

    local function setcam()
        local cf = cam.CFrame;
        local vp = cam.ViewportSize;
        px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents();
        hx, hy = vp.X * .5, vp.Y * .5;
        foc = hy / tan(rad(cam.FieldOfView) * .5);
        return vp;
    end;

    
    local function project(wx, wy, wz)
        local dx, dy, dz = wx - px, wy - py, wz - pz;
        local vx = dx * r00 + dy * r10 + dz * r20;
        local vy = dx * r01 + dy * r11 + dz * r21;
        local vz = dx * r02 + dy * r12 + dz * r22;
        local d = -vz;
        if d <= .05 then return 0, 0, d; end;
        local inv = foc / d;
        return hx + vx * inv, hy - vy * inv, d;
    end;
    es.project = project;

    

    local order, osize, lastsort = {}, 0, 0;
    local iord, iosize, ilastsort = {}, 0, 0;

    local function boxlines(x, y, w, h, c, t, outc, wout)
        local tl, tr2, bl, br = V2(x, y), V2(x + w, y), V2(x, y + h), V2(x + w, y + h);
        if wout then
            line(tl, tr2, outc, t + 2); line(tl, bl, outc, t + 2);
            line(tr2, br, outc, t + 2); line(bl, br, outc, t + 2);
        end;
        line(tl, tr2, c, t); line(tl, bl, c, t);
        line(tr2, br, c, t); line(bl, br, c, t);
    end;

    local function cornerlines(x, y, w, h, c, t, outc, wout, fx, fy)
        local lx, ly = w * fx, h * fy;
        local x2, y2 = x + w, y + h;
        local a1, a2, a3 = V2(x, y), V2(x + lx, y), V2(x, y + ly);
        local b1, b2, b3 = V2(x2, y), V2(x2 - lx, y), V2(x2, y + ly);
        local c1, c2, c3 = V2(x, y2), V2(x + lx, y2), V2(x, y2 - ly);
        local d1, d2, d3 = V2(x2, y2), V2(x2 - lx, y2), V2(x2, y2 - ly);
        if wout then
            local o = t + 2;
            line(a1, a2, outc, o); line(a1, a3, outc, o);
            line(b1, b2, outc, o); line(b1, b3, outc, o);
            line(c1, c2, outc, o); line(c1, c3, outc, o);
            line(d1, d2, outc, o); line(d1, d3, outc, o);
        end;
        line(a1, a2, c, t); line(a1, a3, c, t);
        line(b1, b2, c, t); line(b1, b3, c, t);
        line(c1, c2, c, t); line(c1, c3, c, t);
        line(d1, d2, c, t); line(d1, d3, c, t);
    end;

    
    
    
    local ichamon = false;

    local function iclear()
        if not ichamon then return; end;
        ichamon = false;
        for i = 1, irn do
            local d = rec[iroster[i]];
            if d then unchams(d); end;
        end;
    end;

    local function computeitems()
        local maxd = F.imaxd;
        local now = os.clock();
        if now - ilastsort > .25 or iosize == 0 then
            ilastsort = now;
            iosize = 0;
            for i = 1, irn do
                local p = iroster[i];
                if p.Parent then
                    local pp = p.Position;
                    local dx, dy, dz = px - pp.X, py - pp.Y, pz - pp.Z;
                    if dx * dx + dy * dy + dz * dz <= maxd * maxd then
                        iosize += 1;
                        iord[iosize] = p;
                    elseif ichamon then
                        local d = rec[p];
                        if d then unchams(d); end;
                    end;
                end;
            end;
            for i = iosize + 1, #iord do iord[i] = nil; end;
        end;
        es.items = iosize;
        if not F.icham then iclear(); end;

        local c, outc, t, sz = F.ic, F.outc, F.thick, F.sz;
        for i = 1, iosize do
            local p = iord[i];
            if p.Parent then
                
                
                
                if F.icham then
                    chams(trackrec(p), p, c, outc, F.chamF, F.chamO);
                    ichamon = true;
                end;
                local pp = p.Position;
                local sx, sy, d = project(pp.X, pp.Y, pp.Z);
                if d > 0 then
                    local bh = clamp(foc * 3 / d, 0, hy * 4) * .5;
                    local x, y = sx - bh * .5, sy - bh * .5;
                    if F.icorner then cornerlines(x, y, bh, bh, c, t, outc, F.outline, .3, .3); end;
                    if F.ibox then boxlines(x, y, bh, bh, c, t, outc, F.outline); end;
                    sT, sB, sL, sR = 2, 2, 0, 0;
                    if F.iname then label(p.Name, "Top", c, x, y, bh, bh, 0, 0, sz); end;
                    if F.idist then label(floor(d) .. " studs", "Bottom", c, x, y, bh, bh, 0, 0, sz); end;
                end;
            end;
        end;
    end;

    local function compute()
        bufreset();
        local vp = setcam();
        refresh();

        if F.item then computeitems(); else iclear(); end;
        if not F.plr then es.n = 0; return; end;

        local maxd = F.maxd;
        local cap = F.cap;
        local lvl = es.lvl;
        if lvl >= 2 then cap = math.max(3, floor(cap * .5)); end;
        local wskel = F.skel and lvl < 1;
        local lite = lvl >= 2;

        local now = os.clock();
        if now - lastsort > .2 or osize == 0 then
            lastsort = now;
            osize = 0;
            for i = 1, rn do
                local m = roster[i];
                if m.Parent then
                    local d = trackrec(m);
                    local r = part(d, m, "root", "HumanoidRootPart");
                    if r then
                        local rp = r.Position;
                        local dx, dy, dz = px - rp.X, py - rp.Y, pz - rp.Z;
                        local d2 = dx * dx + dy * dy + dz * dz;
                        if d2 <= maxd * maxd then
                            osize += 1;
                            order[osize] = m;
                            d.d2 = d2;
                        end;
                    end;
                end;
            end;
            for i = osize + 1, #order do order[i] = nil; end;
            if cap > 0 and osize > cap then
                table.sort(order, function(a, b) return (rec[a].d2 or 0) < (rec[b].d2 or 0); end);
            end;
        end;

        local shown = cap > 0 and math.min(osize, cap) or osize;
        es.n = shown;

        local base, outc, thick, sz = F.base, F.outc, F.thick, F.sz;
        local lockc = F.lockc;
        local tgt = nil;
        if F.lock then
            local lk = ctx.lock;
            tgt = lk and lk.tgt or nil;
        end;

        local tx, ty = hx, vp.Y;
        if F.trace then
            if F.tfrom == "Top" then ty = 0;
            elseif F.tfrom == "Middle" then ty = hy;
            elseif F.tfrom == "Mouse" then
                local ml = s.uis:GetMouseLocation();
                tx, ty = ml.X, ml.Y;
            end;
        end;
        local torigin = F.trace and V2(tx, ty) or nil;

        for i = 1, shown do
            local m = order[i];
            if m.Parent then
                local d = rec[m];
                local root = part(d, m, "root", "HumanoidRootPart");
                if root then
                    local rp = root.Position;
                    local sx, sy, dep = project(rp.X, rp.Y, rp.Z);
                    if dep > 0 then
                        
                        
                        
                        local bh = clamp(foc * 6 / dep, 0, vp.Y * 2);
                        local bw = bh / 1.5;
                        local x, y = sx - bw * .5, sy - bh * .5;
                        local c = (tgt and m == tgt) and lockc or base;
                        local far = dep > F.lod;
                        local stn = (F.stun or F.scham) and stunof(d, m) or nil;

                        if F.corner then cornerlines(x, y, bw, bh, c, thick, outc, F.outline, .25, .25); end;
                        if F.box then boxlines(x, y, bw, bh, c, thick, outc, F.outline); end;

                        local hum = d.hum;
                        if not (hum and hum.Parent) then
                            hum = m:FindFirstChildOfClass("Humanoid");
                            d.hum = hum;
                        end;

                        local padL, padR = 0, 0;
                        if F.hpb and hum and hum.MaxHealth > 0 then
                            local f = clamp(hum.Health / hum.MaxHealth, 0, 1);
                            local fh = bh * f;
                            local bx;
                            if F.hside == "Left" then bx = x - 4; padL = 8; else bx = x + bw + 4; padR = 8; end;
                            if F.outline then line(V2(bx, y - 1), V2(bx, y + bh + 1), outc, 5); end;
                            if fh > .5 then line(V2(bx, y + bh), V2(bx, y + bh - fh), F.hbc, 3); end;
                        end;

                        sT, sB, sL, sR = 2, 2, 0, 0;
                        if F.name then label(m.Name, F.npos, c, x, y, bw, bh, padL, padR, sz); end;
                        if F.stun and stn then label(stn, F.spos, F.stunc, x, y, bw, bh, padL, padR, sz); end;
                        if not (far or lite) then
                            if F.char then
                                local ms = m:GetAttribute("Moveset");
                                if ms then label(CHARMAP[ms] or ms, F.cpos, c, x, y, bw, bh, padL, padR, sz); end;
                            end;
                            if F.dist then
                                local fd = floor(dep);
                                if fd ~= d.dist then d.dist = fd; d.disttxt = fd .. " studs"; end;
                                label(d.disttxt, F.dpos, c, x, y, bw, bh, padL, padR, sz);
                            end;
                            if F.hpt and hum then
                                local fh = floor(hum.Health);
                                if fh ~= d.hp then d.hp = fh; d.hptxt = fh .. " HP"; end;
                                label(d.hptxt, F.hpos, F.hbc, x, y, bw, bh, padL, padR, sz);
                            end;
                            if F.kills then
                                local kv = d.kills;
                                if not (kv and kv.Parent) then
                                    local plr = s.plrs:GetPlayerFromCharacter(m);
                                    local ls = plr and plr:FindFirstChild("leaderstats");
                                    local hid = ls and ls:FindFirstChild("Hidden");
                                    kv = (hid and hid:FindFirstChild("Kills")) or (ls and ls:FindFirstChild("Kills"));
                                    d.kills = kv;
                                end;
                                if kv then
                                    local n = kv.Value;
                                    if n ~= d.klast then d.klast = n; d.ktxt = n .. " kills"; end;
                                    label(d.ktxt, F.kpos, c, x, y, bw, bh, padL, padR, sz);
                                end;
                            end;
                        end;

                        if torigin then
                            local to = V2(x + bw * .5, y + bh);
                            if F.outline then line(torigin, to, outc, thick + 2); end;
                            line(torigin, to, c, thick);
                        end;

                        if F.dot and not far then
                            local hd = part(d, m, "head", "Head");
                            if hd then
                                local hp2 = hd.Position;
                                local ax, ay, ad = project(hp2.X, hp2.Y, hp2.Z);
                                if ad > 0 then
                                    local pv = V2(ax, ay);
                                    if F.outline then circ(pv, F.dot_r + 1, outc, thick + 1, false); end;
                                    circ(pv, F.dot_r, c, 1, true);
                                end;
                            end;
                        end;

                        if wskel and not far then
                            local r15 = d.r15;
                            if r15 == nil then r15 = m:FindFirstChild("UpperTorso") ~= nil; d.r15 = r15; end;
                            local sk = r15 and SK15 or SK6;
                            local names, bones = sk.p, sk.b;
                            local proj = d.proj;
                            local cache = d.bp;
                            if not cache then cache = {}; d.bp = cache; end;
                            for pi = 1, #names do
                                local bp = cache[pi];
                                if not (bp and bp.Parent) then bp = m:FindFirstChild(names[pi]); cache[pi] = bp; end;
                                if bp then
                                    local bpp = bp.Position;
                                    local jx, jy, jd = project(bpp.X, bpp.Y, bpp.Z);
                                    proj[pi] = jd > 0 and V2(jx, jy) or false;
                                else
                                    proj[pi] = false;
                                end;
                            end;
                            local skc = F.skc;
                            for bi = 1, #bones, 2 do
                                local a, b = proj[bones[bi]], proj[bones[bi + 1]];
                                if a and b then
                                    if F.outline then line(a, b, outc, thick + 2); end;
                                    line(a, b, skc, thick);
                                end;
                            end;
                        end;

                        if F.cham or F.evade or (F.scham and stn) then
                            local fill = F.chamc;
                            if F.scham and stn then
                                fill = F.schamc;
                            elseif F.evade then
                                local ev = clamp((m:GetAttribute("Evade") or 0) / 50, 0, 1);
                                fill = Color3.new(1 - ev, ev, 0);
                            elseif tgt and m == tgt then
                                fill = lockc;
                            end;
                            chams(d, m, fill, F.chamoc, F.chamF, F.chamO);
                        else
                            unchams(d);
                        end;
                    end;
                end;
            end;
        end;
    end;

    
    
    

    local ema, lvlt = 1 / 60, 0;

    local function govern(dt)
        if dt > 0 and dt < .5 then ema += (dt - ema) * .1; end;
        es.fps = ema > 0 and floor(1 / ema) or 0;
        if not F.auto then es.lvl = 0; return; end;
        local now = os.clock();
        if now - lvlt < 1 then return; end;
        if ema > 1 / 50 and es.lvl < 3 then
            es.lvl += 1; lvlt = now;
        elseif ema < 1 / 70 and es.lvl > 0 then
            es.lvl -= 1; lvlt = now;
        end;
    end;

    local conn, last, cacc = nil, 0, 0;

    function es.sync()
        es.set(on("EspOn") or on("EspItemOn"));
    end;

    function es.set(v)
        es.on = v == true;
        if not es.on then
            if conn then conn:Disconnect(); conn = nil; end;
            bufreset();
            sweep();
            return;
        end;
        if conn then return; end;
        bindroster();
        snapflags();
        flagt = os.clock();
        last = os.clock();
        local function frame()
            if not es.on then return; end;
            local now = os.clock();
            local dt = now - last;
            last = now;
            govern(dt);
            if now - flagt > .1 then flagt = now; snapflags(); end;
            
            
            local due = true;
            if es.lvl >= 3 then
                cacc += dt;
                if cacc < 1 / 60 then due = false; else cacc = 0; end;
            end;
            if due then
                local ok, err = pcall(compute);
                if not ok then
                    es.err = tostring(err);
                    bufreset();
                end;
            end;
            paint();
        end;
        
        
        conn = imm and di.GetPaint():Connect(frame) or s.runs.RenderStepped:Connect(frame);
        ut.add(conn);
    end;

    function es.stop()
        es.on = false;
        if conn then conn:Disconnect(); conn = nil; end;
        es.reveal(false);
        iclear();
        for _, c in rconns do pcall(function() c:Disconnect(); end); end;
        table.clear(rconns);
        for _, nm in { "Characters", "Items" } do
            local box = workspace:FindFirstChild(nm);
            if box then
                for _, m in box:GetChildren() do
                    local d = rec[m];
                    if d then unchams(d); end;
                end;
            end;
        end;
        table.clear(order);
        table.clear(iord);
        table.clear(roster);
        table.clear(iroster);
        osize, iosize, rn, irn, es.n, es.items = 0, 0, 0, 0, 0, 0;
        bufreset();
        wipe();
    end;

    return es;
end;

end)();
local _M21 = (function()
return function(ctx)
    local s, ut = ctx.svc, ctx.ut;
    local iv = { on = false };
    local OFF = 100;
    local fake, rconn, trk, apc, cadd, crem, cconn, oc0, rj = nil, nil, nil, nil, nil, nil, nil, nil, nil;
    local parts, occ = {}, ut.weak();

    local function rootj(c)
        local h = c and c:FindFirstChild("HumanoidRootPart");
        local j = h and h:FindFirstChild("RootJoint");
        if j then return j; end;
        local lt = c and c:FindFirstChild("LowerTorso");
        return lt and lt:FindFirstChild("Root") or nil;
    end;

    local function keep(p)
        if occ[p] == nil then occ[p] = p.CanCollide; end;
        parts[#parts + 1] = p;
    end;

    local function rebuild(c)
        table.clear(parts);
        if not c then return; end;
        for _, v in c:GetDescendants() do
            if v:IsA("BasePart") then keep(v); end;
        end;
    end;

    local function medanim()
        local a = s.rs:FindFirstChild("Modules");
        a = a and a:FindFirstChild("MVP");
        a = a and a:FindFirstChild("Meditation");
        return a and a:FindFirstChild("Character") or nil;
    end;

    local function killfb()
        if rconn then rconn:Disconnect(); rconn = nil; end;
        if apc then apc:Disconnect(); apc = nil; end;
        if fake then pcall(fake.Destroy, fake); fake = nil; end;
        if trk then
            pcall(function() trk:Stop(); end);
            trk = nil;
        end;
        local h = ut.alive(s.lp.Character);
        if h then
            h.AutoRotate = true;
            workspace.CurrentCamera.CameraSubject = h;
        end;
    end;

    local function step()
        local c = s.lp.Character;
        local r = c and c:FindFirstChild("HumanoidRootPart");
        if not r then return; end;
        if rj and rj.Parent and oc0 then
            local t = oc0 - Vector3.new(0, OFF, 0);
            if rj.C0 ~= t then rj.C0 = t; end;
        end;
        for i = 1, #parts do
            local p = parts[i];
            if p.Parent and p.CanCollide then p.CanCollide = false; end;
        end;
        local lv = workspace.CurrentCamera.CFrame.LookVector;
        local look = Vector3.new(lv.X, 0, lv.Z);
        if look.Magnitude > 0 then
            r.CFrame = CFrame.new(r.Position, r.Position + look.Unit);
        end;
        if fake then fake.CFrame = r.CFrame * CFrame.new(0, 1.5, 0); end;
    end;

    local function pin(hum)
        local a = medanim();
        if not a then return; end;
        local anm = hum:FindFirstChildOfClass("Animator") or hum;
        local ok, t = pcall(anm.LoadAnimation, anm, a);
        if not (ok and t) then return; end;
        trk = t;
        t.Priority = Enum.AnimationPriority.Action4;
        t:Play();
        task.wait(.1);
        if trk ~= t or not iv.on then return; end;
        t.TimePosition = .1;
        t:AdjustSpeed(0);
        for _, o in ut.tracks(anm) do
            if o ~= t then o:Stop(0); end;
        end;
        if apc then apc:Disconnect(); end;
        apc = hum.AnimationPlayed:Connect(function(nt)
            if iv.on and nt ~= trk then nt:Stop(0); end;
        end);
    end;

    local function start(c)
        local hum = c and c:FindFirstChildOfClass("Humanoid");
        local hrp = c and c:FindFirstChild("HumanoidRootPart");
        if not (hum and hrp) then return false; end;
        killfb();
        rj = rootj(c);
        if rj then
            oc0 = rj.C0;
            rj.C0 = oc0 - Vector3.new(0, OFF, 0);
        end;
        rebuild(c);
        if cadd then cadd:Disconnect(); end;
        if crem then crem:Disconnect(); end;
        cadd = c.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") then keep(d); end;
        end);
        crem = c.DescendantRemoving:Connect(function(d)
            if not d:IsA("BasePart") then return; end;
            for i = 1, #parts do
                if parts[i] == d then
                    parts[i] = parts[#parts];
                    parts[#parts] = nil;
                    return;
                end;
            end;
        end);
        pcall(function() s.lp.DevEnableMouseLock = true; end);
        hum.AutoRotate = false;
        local f = Instance.new("Part");
        f.Name = "JJSFakeTorso";
        f.Size = Vector3.new(2, 2, 1);
        f.Transparency = 1;
        f.CanCollide = false;
        f.Anchored = true;
        f.Parent = workspace;
        fake = f;
        local cm = workspace.CurrentCamera;
        cm.CameraType = Enum.CameraType.Custom;
        cm.CameraSubject = f;
        rconn = s.runs.RenderStepped:Connect(function()
            if iv.on then step(); end;
        end);
        task.spawn(pin, hum);
        return true;
    end;

    local function undo()
        iv.on = false;
        if cadd then cadd:Disconnect(); cadd = nil; end;
        if crem then crem:Disconnect(); crem = nil; end;
        killfb();
        local c = s.lp.Character;
        if c then
            local j = (rj and rj.Parent) and rj or rootj(c);
            if j and oc0 then j.C0 = oc0; end;
            for _, v in c:GetDescendants() do
                if v:IsA("BasePart") then
                    local o = occ[v];
                    v.CanCollide = o == nil or o;
                end;
            end;
        end;
        oc0, rj = nil, nil;
        table.clear(parts);
    end;

    function iv.stop()
        if cconn then cconn:Disconnect(); cconn = nil; end;
        undo();
    end;

    function iv.set(v)
        if v ~= true then
            iv.stop();
            return true;
        end;
        if iv.on then return true; end;
        iv.on = true;
        if not start(s.lp.Character) then
            iv.on = false;
            return false;
        end;
        if not cconn then
            cconn = s.lp.CharacterAdded:Connect(function(c)
                if not iv.on then return; end;
                oc0, rj = nil, nil;
                c:WaitForChild("HumanoidRootPart", 5);
                c:WaitForChild("Humanoid", 5);
                if iv.on then start(c); end;
            end);
        end;
        return true;
    end;

    return iv;
end;

end)();
local _M22 = (function()
return function(ctx)
    local s, ut = ctx.svc, ctx.ut;
    local vt = { on = false, lead = nil };

    local PLEAS = { "DenialCount", "SilenceCount", "ConfessCount" };
    local NAMES = { "Denial", "Silence", "Confess" };

    local gui, txt, dom, rem, ds = nil, nil, nil, nil, nil;
    local dconns, wconns, drag = {}, {}, nil;

    local function winid(d)
        local a = d:GetAttribute("DenialCount") or 0;
        local b = d:GetAttribute("SilenceCount") or 0;
        local c = d:GetAttribute("ConfessCount") or 0;
        if a <= 0 and b <= 0 and c <= 0 then return nil, a, b, c; end;
        if a >= b and a >= c then return 1, a, b, c; end;
        if b >= c then return 2, a, b, c; end;
        return 3, a, b, c;
    end;

    local function draw()
        if not txt then return; end;
        if not dom then
            txt.Text = "Vote\nwaiting";
            txt.TextColor3 = ctx.lib and ctx.lib.theme.dim or Color3.fromRGB(140, 140, 140);
            return;
        end;
        local w, a, b, c = winid(dom);
        txt.Text = (w and NAMES[w] or "Vote") .. ("\n%d  %d  %d"):format(a, b, c);
        local th = ctx.lib and ctx.lib.theme;
        txt.TextColor3 = th and (w and th.txt or th.dim) or Color3.fromRGB(240, 240, 240);
    end;

    local function make()
        if gui then return; end;
        local th = ctx.lib and ctx.lib.theme;
        gui = Instance.new("ScreenGui");
        gui.Name = "vv";
        gui.DisplayOrder = 998;
        gui.ResetOnSpawn = false;
        gui.IgnoreGuiInset = true;
        gui.Parent = gethui and gethui() or game:GetService("CoreGui");
        local f = Instance.new("TextButton");
        f.AutoButtonColor = false;
        f.Text = "";
        f.BorderSizePixel = 0;
        f.AnchorPoint = Vector2.new(.5, 0);
        f.Position = UDim2.new(.5, 0, 0, 64);
        f.Size = UDim2.fromOffset(112, 44);
        f.BackgroundColor3 = th and th.bg or Color3.fromRGB(12, 12, 12);
        f.BackgroundTransparency = .1;
        f.Parent = gui;
        local cr = Instance.new("UICorner");
        cr.CornerRadius = UDim.new(0, 10);
        cr.Parent = f;
        local st = Instance.new("UIStroke");
        st.Color = th and th.line or Color3.fromRGB(40, 40, 40);
        st.Thickness = 1;
        st.Parent = f;
        txt = Instance.new("TextLabel");
        txt.BackgroundTransparency = 1;
        txt.Size = UDim2.new(1, -12, 1, -8);
        txt.Position = UDim2.fromOffset(6, 4);
        txt.Font = Enum.Font.GothamBold;
        txt.TextSize = 13;
        txt.TextColor3 = th and th.txt or Color3.fromRGB(240, 240, 240);
        txt.Parent = f;

        local st0, p0 = nil, nil;
        wconns[#wconns + 1] = f.InputBegan:Connect(function(i)
            local u = i.UserInputType;
            if u ~= Enum.UserInputType.Touch and u ~= Enum.UserInputType.MouseButton1 then return; end;
            st0, p0 = i.Position, f.Position;
        end);
        wconns[#wconns + 1] = s.uis.InputChanged:Connect(function(i)
            if not (st0 and p0) then return; end;
            local u = i.UserInputType;
            if u ~= Enum.UserInputType.Touch and u ~= Enum.UserInputType.MouseMovement then return; end;
            local d = i.Position - st0;
            f.Position = UDim2.new(p0.X.Scale, p0.X.Offset + d.X, p0.Y.Scale, p0.Y.Offset + d.Y);
        end);
        wconns[#wconns + 1] = s.uis.InputEnded:Connect(function(i)
            local u = i.UserInputType;
            if u == Enum.UserInputType.Touch or u == Enum.UserInputType.MouseButton1 then st0, p0 = nil, nil; end;
        end);
        drag = f;
    end;

    local function check()
        if not dom then return; end;
        local w = winid(dom);
        if w ~= vt.lead then vt.lead = w; end;
        draw();
    end;

    local function cleardom()
        ut.drop(dconns);
        dom, rem, vt.lead = nil, nil, nil;
        draw();
    end;

    local function binddom(d)
        cleardom();
        if not d then return; end;
        dom = d;
        rem = d:FindFirstChild("UnreliableRemoteEvent");
        dconns[#dconns + 1] = d.ChildAdded:Connect(function(c)
            if c.Name == "UnreliableRemoteEvent" then rem = c; check(); end;
        end);
        for _, a in PLEAS do
            dconns[#dconns + 1] = d:GetAttributeChangedSignal(a):Connect(check);
        end;
        check();
    end;

    local function bindbox(box)
        if ds == box then return; end;
        ds = box;
        wconns[#wconns + 1] = box.ChildAdded:Connect(function(c)
            if c.Name == "Domain" then binddom(c); end;
        end);
        wconns[#wconns + 1] = box.ChildRemoved:Connect(function(c)
            if c == dom then cleardom(); end;
        end);
        binddom(box:FindFirstChild("Domain"));
    end;

    function vt.stop()
        vt.on = false;
        cleardom();
        ut.drop(wconns);
        ds = nil;
        txt, drag = nil, nil;
        if gui then
            gui:Destroy();
            gui = nil;
        end;
    end;

    function vt.set(v)
        if v ~= true then
            vt.stop();
            return;
        end;
        if vt.on then return; end;
        vt.stop();
        vt.on = true;
        make();
        draw();
        local box = workspace:FindFirstChild("Domains");
        if box then
            bindbox(box);
        else
            wconns[#wconns + 1] = workspace.ChildAdded:Connect(function(c)
                if c.Name == "Domains" then bindbox(c); end;
            end);
        end;
    end;

    return vt;
end;

end)();
local _M23 = (function()
return function(ctx)
    local s, ut = ctx.svc, ctx.ut;
    local av = {};

    local SHIRTS = { 144076760, 382537702, 144076436, 92684399, 398635338 };
    local PANTS = { 398635081, 144076760, 144076512, 382538503, 1072688 };
    local FACES = { 7074764, 7074729, 494290547, 62078357, 8560971 };
    local HATS = { 1029025, 121389565, 1125510, 62234425, 17374874 };
    local HAIRS = { 63690008, 451220849, 74891501, 451221329, 62241601 };
    local UIDS = { 1, 261, 156, 2789, 49193, 16960679, 1762827052, 20350467 };

    local CLOTHES = {};
    for _, t in { SHIRTS, PANTS } do
        for _, id in t do CLOTHES[#CLOTHES + 1] = id; end;
    end;

    local function pick(t) return t[math.random(1, #t)]; end;

    local function parts()
        local c = s.lp.Character;
        return c, c and c:FindFirstChildOfClass("Humanoid");
    end;

    
    
    
    local function strip(c, keepcol)
        for _, v in c:GetChildren() do
            if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants")
                or v:IsA("ShirtGraphic") or v:IsA("CharacterMesh")
                or (v:IsA("BodyColors") and not keepcol) then
                pcall(v.Destroy, v);
            end;
        end;
    end;

    local function grab(id)
        local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id); end);
        if not (ok and type(objs) == "table") then return nil; end;
        return objs;
    end;

    local function wear(c, a)
        local ac = a:Clone();
        for _, p in ac:GetDescendants() do
            if p:IsA("BasePart") then
                p.Anchored = false;
                p.CanCollide = false;
                p.Massless = true;
            end;
        end;
        local hd = ac:FindFirstChild("Handle");
        if not hd then ac:Destroy(); return; end;
        local at = hd:FindFirstChildWhichIsA("Attachment");
        local tgt = nil;
        if at then
            for _, d in c:GetDescendants() do
                if d:IsA("Attachment") and d.Name == at.Name and not d:IsDescendantOf(ac) then
                    tgt = d;
                    break;
                end;
            end;
        end;
        ac.Parent = c;
        local w = Instance.new("Weld");
        w.Name = "AccessoryWeld";
        w.Part0 = hd;
        if tgt then
            w.Part1 = tgt.Parent;
            w.C0 = at.CFrame;
            w.C1 = tgt.CFrame;
        else
            w.Part1 = c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart");
        end;
        w.Parent = hd;
    end;

    
    
    
    local function clonefrom(m)
        local c, h = parts();
        if not (c and h and m) then return false, "no character"; end;
        strip(c);
        for _, cls in { "Shirt", "Pants", "ShirtGraphic", "BodyColors" } do
            local src = m:FindFirstChildOfClass(cls);
            if src then pcall(function() src:Clone().Parent = c; end); end;
        end;
        local ch, mh = c:FindFirstChild("Head"), m:FindFirstChild("Head");
        if ch and mh then
            local sf = mh:FindFirstChild("face") or mh:FindFirstChildWhichIsA("Decal");
            if sf and sf:IsA("Decal") then
                local df = ch:FindFirstChild("face") or ch:FindFirstChildWhichIsA("Decal");
                if df and df:IsA("Decal") then df.Texture = sf.Texture;
                else pcall(function() sf:Clone().Parent = ch; end); end;
            end;
        end;
        for _, a in m:GetDescendants() do
            if a:IsA("Accessory") then pcall(wear, c, a); end;
        end;
        return true;
    end;

    local function resolve(who)
        local uid = tonumber(who);
        if uid then return uid; end;
        local nm = tostring(who or ""):gsub("^%s+", ""):gsub("%s+$", "");
        if nm == "" then return nil; end;
        for _, p in s.plrs:GetPlayers() do
            if p.Name:lower() == nm:lower() or p.DisplayName:lower() == nm:lower() then return p.UserId; end;
        end;
        local ok, id = pcall(s.plrs.GetUserIdFromNameAsync, s.plrs, nm);
        return ok and tonumber(id) or nil;
    end;

    function av.copy(who)
        local uid = resolve(who);
        if not uid or uid <= 0 then return false, "user not found"; end;
        local mok, m = pcall(s.plrs.CreateHumanoidModelFromUserId, s.plrs, uid);
        if not (mok and m) then return false, "fetch failed"; end;
        local cok, why = clonefrom(m);
        pcall(m.Destroy, m);
        if not cok then return false, why; end;
        return true, uid;
    end;

    local function face(c, d)
        local hd = c:FindFirstChild("Head");
        if not hd then return; end;
        local cur = hd:FindFirstChild("face") or hd:FindFirstChildWhichIsA("Decal");
        if cur and cur:IsA("Decal") then cur.Texture = d.Texture else d.Parent = hd end;
    end;

    
    
    function av.rand()
        local c = s.lp.Character;
        if not c then return false, "no character"; end;
        local ids = { pick(FACES), pick(HATS), pick(HAIRS) };
        
        
        
        for _ = 1, 4 do ids[#ids + 1] = pick(CLOTHES); end;
        local bags = {};
        for _, id in ids do
            local o = grab(id);
            if o then bags[#bags + 1] = o; end;
        end;
        if #bags == 0 then return false, "asset fetch failed"; end;
        if not c.Parent then return false, "no character"; end;
        strip(c, true);
        local got, n = {}, 0;
        for _, objs in bags do
            for _, o in objs do
                local k = o.ClassName;
                if o:IsA("Accessory") then
                    pcall(wear, c, o);
                    n += 1;
                elseif o:IsA("Decal") then
                    if not got.face then got.face = true; pcall(face, c, o); n += 1; end;
                elseif o:IsA("Shirt") or o:IsA("Pants") or o:IsA("ShirtGraphic") then
                    if not got[k] then got[k] = true; o.Parent = c; n += 1; end;
                end;
            end;
        end;
        local bc = c:FindFirstChildOfClass("BodyColors");
        if not bc then
            bc = Instance.new("BodyColors");
            bc.Parent = c;
        end;
        local col = Color3.fromHSV(math.random(), .7, 1);
        bc.HeadColor3, bc.TorsoColor3 = col, col;
        bc.LeftArmColor3, bc.RightArmColor3 = col, col;
        bc.LeftLegColor3, bc.RightLegColor3 = col, col;
        return true, n .. " parts";
    end;

    function av.randplayer()
        for _ = 1, 4 do
            local uid = pick(UIDS);
            local ok = av.copy(uid);
            if ok then return true, uid; end;
        end;
        return false, "fetch failed";
    end;

    function av.restore()
        return av.copy(s.lp.UserId);
    end;

    return av;
end;

end)();
local _M24 = (function()
return function(ctx)
    local s, ut, opt = ctx.svc, ctx.ut, ctx.opt;
    local bf, lk, bk, fl = ctx.bfc, ctx.lock, ctx.block, ctx.filter;
    local bb = { active = false, on = false };
    local last, poll, lkown = 0, 0, false;
    local conns = {};

    local function num(k, d)
        return tonumber(opt(k, d)) or d;
    end;

    
    
    local blkids, nanids = {}, {};
    do
        local misc = s.animfld and s.animfld:FindFirstChild("Misc");
        local blk = misc and misc:FindFirstChild("Block");
        if blk then
            for _, a in blk:GetDescendants() do
                if a:IsA("Animation") then
                    local id = fl.normid(a.AnimationId);
                    blkids[id] = true;
                    if a.Name:lower() == "nanami2" then nanids[id] = true; end;
                end;
            end;
        end;
    end;
    bb.ids = blkids;

    local function isblk(t, exn)
        if not (t and t.Parent) then return false; end;
        local h = t:FindFirstChildOfClass("Humanoid");
        if not h then return false; end;
        local ok, trks = pcall(ut.tracks, h);
        if not (ok and trks) then return false; end;
        for _, tr in trks do
            local a = tr.Animation;
            if a then
                local id = fl.normid(a.AnimationId);
                if blkids[id] and not (exn and nanids[id]) then return true; end;
            end;
        end;
        return false;
    end;
    bb.blocking = isblk;

    local function pick(exn, maxd)
        local t = lk and lk.tgt;
        if t and t.Parent and isblk(t, exn) then return t; end;
        if opt("BBOnlyLocked", false) == true then return nil; end;
        if opt("BBOnlySelected", false) == true then
            local nm = opt("BBTarget", "None");
            if nm == "None" then return nil; end;
            for _, c in ut.chars() do
                if c.Name == nm and isblk(c, exn) then return c; end;
            end;
            return nil;
        end;
        local c = bf.closest(maxd);
        if c and isblk(c, exn) then return c; end;
        return nil;
    end;

    local function dolock(tgt)
        if opt("BBLock", false) ~= true or lkown then return; end;
        if opt("LockOn", false) == true then return; end;
        lkown = true;
        lk.hold(true);
        lk.start(tgt);
    end;

    local function undolock()
        if not lkown then return; end;
        lkown = false;
        lk.hold(false);
        if opt("LockBlock", false) ~= true then lk.stop(); end;
    end;

    
    
    function bb.fire(tgt, force, exn)
        if (not bb.on and not force) or bb.active then return false; end;
        local now = os.clock();
        if now - last < num("BBCd", 1) then return false; end;
        local maxd = num("BBDist", 30);
        tgt = tgt or pick(exn, maxd);
        if not (tgt and isblk(tgt, exn)) then return false; end;
        local ch = s.lp.Character;
        if not ch or bf.stunned(ch) then return false; end;
        local hrp, thrp = ut.hrp(ch), ut.hrp(tgt);
        if not (hrp and thrp) then return false; end;
        if ut.dist2sq(hrp.Position, thrp.Position) > maxd * maxd then return false; end;
        bb.active, last = true, now;
        dolock(tgt);
        if not bf.arcdash(tgt, "BB") then
            bb.active = false;
            undolock();
            return false;
        end;
        if bk and opt("BBPunish", true) == true then
            task.delay(num("BBPunishT", .12), function()
                if tgt.Parent then bk.punish(true, maxd); end;
            end);
        end;
        
        
        task.delay(.5, function()
            bb.active = false;
            undolock();
        end);
        return true;
    end;

    function bb.start()
        if bb.on then return; end;
        bb.on = true;
        
        
        conns[#conns + 1] = s.runs.Heartbeat:Connect(function()
            if opt("BBAuto", false) ~= true or bb.active then return; end;
            local now = os.clock();
            if now < poll then return; end;
            poll = now + .15;
            bb.fire(nil, false, true);
        end);
        
        
        conns[#conns + 1] = s.uis.InputBegan:Connect(function(i, gp)
            if gp or opt("BBM1", false) ~= true then return; end;
            local u = i.UserInputType;
            if u ~= Enum.UserInputType.MouseButton1 and u ~= Enum.UserInputType.Touch then return; end;
            bb.fire();
        end);
        for _, c in conns do ut.add(c); end;
    end;

    function bb.stop()
        bb.on, bb.active = false, false;
        ut.drop(conns);
        undolock();
    end;

    function bb.sync()
        if opt("BBAuto", false) == true or opt("BBM1", false) == true then bb.start();
        elseif bb.on then bb.stop(); end;
    end;

    return bb;
end;

end)();
local _M25 = (function()
return function(ctx)
    local htp = ctx.svc.http;
    local lg = { found = {}, names = {} };
    local floor, clamp = math.floor, math.clamp;

    local dirs = {
        "XenonHubRewrite/Jujutsu Shenanigans/settings",
        "XenonHub/Jujutsu Shenanigans/settings",
        "XenonHubRewrite/settings",
        "XenonHub/settings",
    };

    local map = {
        ablEnabled = "ABEnabled",
        ablLocked = "ABOnlyLocked",
        ablOnlyTgt = "ABOnlySelected",
        ablRange = "ABRange",
        ablTgtList = { "ABTarget", "SDATarget", "BBTarget", "LockBlockTarget" },
        hbm1 = "ABHoldM1",
        hbcount = "ABHitCount",
        hbto = "ABHoldTimeout",
        apEnabled = "ABPunish",
        apRange = "ABPunishRange",
        apPunDash = "ABDashPunish",
        apPunDashT = "ABDashPunishT",
        m1Catch = "M1Catch",
        m1CatchRange = "M1CatchRange",
        autoCT = "AutoCounter",
        ctRange = "CTRange",
        ctFrontOnly = "CTFront",

        bfchOn = "BFCEnabled",
        bfchStartKey = "BFCChainKey",
        bfchAutoLock = "BFCAutoLock",
        bfchAutoAng = "DFArcAutoAngle",
        bfchAngDeg = "DFArcAngleVal",
        autoBF = "AutoBlackFlash",
        AutoFeintBFC = "AutoFeintBFC",
        DFArcNoStick = "DFArcNoStick",
        DFArcDist = "DFArcDist",
        DFArcDelay = "ABFDelay",
        BFCCooldown = "BFCCooldown",
        BFCCustomize = "BFCCustomize",
        BFCCurve = "BFCCurve",
        BFCCurveType = "BFCCurveType",
        BFCCycleCurve = "BFCCycleCurve",
        BFCCurveDash = "BFCCurveDash",
        BFCBackPred = "BFCBackPred",
        BFCBackPredStrength = "BFCBackPredStrength",
        BFCArcRadius = "BFCArcRadius",
        BFCArcDuration = "BFCArcDuration",
        BFCMaxArcSpeed = "BFCMaxArcSpeed",
        BFCDashMultCap = "BFCDashMultCap",
        BFCCorrectionSpeed = "BFCCorrectionSpeed",
        BFCCurvePow = "BFCCurvePow",
        BFCCurveFloor = "BFCCurveFloor",

        sdaOn = "SDAOn",
        sdaKey = "SDAFireKey",
        sdaOnlyLocked = "SDAOnlyLocked",
        sdaOnlyTgt = "SDAOnlySelected",
        sdaAutoLock = "SDALock",
        sdaPunish = "SDAPunish",
        sdaMaxDist = "SDADist",
        sdaCd = "SDACd",
        sdaPunT = "SDAPunishT",
        SDACustomize = "SDACustomize",
        SDAArcRadius = "SDAArcRadius",
        SDAArcDuration = "SDAArcDuration",
        SDAMaxArcSpeed = "SDAMaxArcSpeed",
        SDADashMultCap = "SDADashMultCap",
        SDACorrectionSpeed = "SDACorrectionSpeed",

        bbAuto = "BBAuto",
        bbM1 = "BBM1",
        bbOnlyLk = "BBOnlyLocked",
        bbKey = "BBKey",
        bbRange = "BBDist",
        bbCd = "BBCd",

        lockon = "LockOn",
        lockOnBlock = "LockBlock",
        lockOnBlockMode = "LockBlockMode",
        lockmode = "LockTargetMode",
        lockmethod = "LockMethod",
        lockSmooth = "LockSmoothing",
        pcLockOffX = "LockCamX",
        pcLockOffY = "LockCamY",
        pcLockOffZ = "LockCamZ",

        espEnabled = "EspOn",
        espMaxDist = "EspDist",
        espMaxTargets = "EspMax",
        espThick = "EspThick",
        espTextSize = "EspTextSize",
        espColor = "EspColor",
        espOutline = "EspOutColor",
        espLockEsp = "EspLock",
        espLockEspColor = "EspLockColor",
        espCorner = "EspCorner",
        espBox = "EspBox",
        espBoxOut = "EspOutline",
        espHead = "EspHeadDot",
        espSkel = "EspSkel",
        espSkelColor = "EspSkelColor",
        espTracer = "EspTracer",
        espTracerOrigin = "EspTracerFrom",
        espNames = "EspNames",
        espPosName = "EspNamePos",
        espChar = "EspChar",
        espPosChar = "EspCharPos",
        espDist = "EspDistance",
        espPosDist = "EspDistPos",
        espKills = "EspKills",
        espPosKills = "EspKillPos",
        espHealthBar = "EspHealthBar",
        espPosHealthBar = "EspHealthSide",
        espHealthT = "EspHealthT",
        espPosHealthT = "EspHealthPos",
        espHealthColor = "EspHealthColor",
        espChams = "EspChams",
        espChamsFill = "EspChamsColor",
        espChamsOutline = "EspChamsOutColor",
        espChamsTrans = "EspChamsFill",
        espEvasiveChams = "EspEvasive",
        espReveal = "EspReveal",

        utHitbox = "Hitbox",
        utHitboxSize = "HitboxSize",
        utAutoRoll = "AutoRoll",
        utInvis = "Invis",
        wsOn = "WSOn",
        wsVal = "WSVal",
        noStun = "AntiStun",
        noDashCd = "InfDash",
        autoSurf = "AutoSurf",
        surfRange = "SurfRange",
        surfStick = "SurfStick",

        autoHK4 = "AutoHK4",
        autoHKB = "AutoHKB",
        autoGojo3R = "AutoGojo3R",
        autoGojo4R = "AutoGojo4R",
        gojoAirHeight = "GojoAirMin",
        autoMToadNue = "AutoMegToad",
        autoMBirdFly = "AutoMegBird",
        autoMShadowRabbit = "AutoMegRabbit",
        mShadowRabbitRange = "MegRabbitRange",
        autoHig4th = "AutoHig4",
        autoQTE = "AutoHiguQTE",
        voteView = "VoteView",
        autoRYUDash1 = "AutoRyuDash1",
        autoPerfClap = "AutoTodoClap",

        auraOn = "AuraOn",
        auraColor = "AuraColor",
        auraRainbow = "AuraRainbow",
        auraGrad = "AuraGrad",
        auraRainbowSpd = "AuraSpeed",
        auraG1 = "AuraG1",
        auraG2 = "AuraG2",
        auraG3 = "AuraG3",
        auraG4 = "AuraG4",
        efxOn = "EfxOn",
        efxColor = "EfxColor",
        efxRainbow = "EfxRainbow",
        efxGrad = "EfxGrad",
        efxRainbowSpd = "EfxSpeed",
        efxG1 = "EfxG1",
        efxG2 = "EfxG2",
        efxG3 = "EfxG3",
        efxG4 = "EfxG4",
        musOn = "MusOn",
        musFile = "MusFile",
        musVol = "MusVol",
        musStart = "MusStart",
        musClip = "MusClip",
        bfhkOn = "BfsOn",
        bfhkFile = "BfsFile",
        bfhkVol = "BfsVol",
        bfhkStart = "BfsStart",
        bfhkClip = "BfsClip",

        MobileBtn = "MobileBtns",
        LockMobileBtn = "MobileLock",
        MobileBtnList = "MobileList",

        MenuKeybind = "ui_menu",
        KeybindMenuOpen = "ui_klist",
        AccentGradientStart = "ui_c_acc",
    };

    local kbmap = {
        bfchOn = "BFCChainKey",
        sdaOn = "SDAKey",
        ablEnabled = "ABKey",
        autoCT = "CTKey",
        lockon = "LockKey",
        lockOnBlock = "LockBlockKey",
        wsOn = "WSKey",
        utInvis = "InvisKey",
        voteView = "VoteViewKey",
    };

    local vmap = {
        lockmode = {
            Closest = "Closest",
            ["Lowest Health"] = "Closest",
            ["Middle of Screen"] = "Crosshair",
            ["Closest to Mouse"] = "Crosshair",
        },
        lockOnBlockMode = {
            ["Closest Player"] = "Closest",
            ["Middle of Screen"] = "Closest",
            ["Closest to Mouse"] = "Closest",
        },
    };

    local nmap = {
        lockSmooth = function(n) return (clamp(n, 2, 100) - 2) / 98; end,
        espMaxTargets = function(n) return n <= 0 and 30 or n; end,
    };

    local modes = { Always = "Always", Toggle = "Toggle", Hold = "Hold", Press = "Hold" };

    local function first(f)
        return type(f) == "table" and f[1] or f;
    end;

    local function hex(s)
        local n = tonumber(tostring(s), 16);
        if not n then return nil; end;
        return { floor(n / 65536) % 256 / 255, floor(n / 256) % 256 / 255, n % 256 / 255 };
    end;

    local function conv(o, e, idx)
        local ty = e.type;
        if ty == "ColorPicker" then
            if o.t ~= "colorpicker" then return nil; end;
            local c = hex(e.value);
            return c and { c = c, a = tonumber(e.transparency) or 0 } or nil;
        end;
        if ty == "KeyPicker" then
            if o.t ~= "keybind" then return nil; end;
            local k = e.key;
            if k == nil or k == "None" or k == "Unknown" or k == "" then return nil; end;
            return { k = k, m = modes[e.mode] or "Toggle" };
        end;

        local v = ty == "Input" and e.text or e.value;
        if v == nil then return nil; end;

        local vm = vmap[idx];
        if vm and type(v) == "string" then
            v = vm[v];
            if v == nil then return nil; end;
        end;
        local nf = nmap[idx];
        if nf then v = nf(tonumber(v) or 0); end;

        local t = o.t;
        if t == "toggle" then return v == true; end;
        if t == "slider" then return tonumber(v); end;
        if t == "input" then return type(v) == "string" and v or nil; end;
        if t ~= "dropdown" then return nil; end;

        local ok = {};
        for _, n in o.vals do ok[n] = true; end;
        if not o.multi then
            v = tostring(v);
            return ok[v] and v or nil;
        end;
        if type(v) ~= "table" then return nil; end;
        local sel, n = {}, 0;
        for k, on in v do
            if on and ok[k] then
                sel[k] = true;
                n += 1;
            end;
        end;
        return n > 0 and sel or nil;
    end;

    function lg.convert(objs)
        local l = ctx.lib;
        if not (l and type(objs) == "table") then return nil, 0, 0; end;
        local opts = l.opts;
        local out, src, binds = {}, {}, {};
        local hit, miss = 0, 0;

        local function put(f, e, idx)
            local o = opts[f];
            if not o then return false; end;
            local v = conv(o, e, idx);
            if v == nil then return false; end;
            out[f] = v;
            return true;
        end;

        for _, e in objs do
            local idx = e.idx;
            if type(idx) == "string" then
                if e.value ~= nil then src[idx] = e.value; end;
                if e.type == "KeyPicker" and idx:sub(-3) == "_kb" then
                    binds[#binds + 1] = e;
                else
                    local f = map[idx];
                    if f == nil then
                        miss += 1;
                    elseif type(f) == "table" then
                        local any = false;
                        for _, one in f do
                            if put(one, e, idx) then any = true; end;
                        end;
                        if any then hit += 1; else miss += 1; end;
                    elseif put(f, e, idx) then
                        hit += 1;
                    else
                        miss += 1;
                    end;
                end;
            end;
        end;

        for _, e in binds do
            local base = e.idx:sub(1, -4);
            local f = kbmap[base];
            if not f then
                local t = first(map[base]);
                f = t and (t .. "_key") or nil;
            end;
            if f and out[f] == nil then put(f, e, base); end;
        end;

        if src.alwaysUp == true then
            out.LastM1 = "Uppercut";
        elseif src.alwaysDown == true then
            out.LastM1 = "Downslam";
        end;
        if src.lockBoth == true then out.LockMethod = "Both"; end;

        return out, hit, miss;
    end;

    function lg.apply(out)
        local l = ctx.lib;
        if not (l and out) then return 0; end;
        local n = 0;
        l.loading = true;
        for f, v in out do
            local o = l.opts[f];
            if o and o.Des and pcall(o.Des, o, v) then n += 1; end;
        end;
        l.loading = false;
        l.tpend = false;
        pcall(l.Apply, l);
        return n;
    end;

    function lg.scan()
        table.clear(lg.found);
        table.clear(lg.names);
        local v = { "None" };
        if not (listfiles and isfolder) then return v; end;
        local l = ctx.lib;
        local drop = l and l.dir and (l.dir .. "/legacy");
        if drop and makefolder and not isfolder(drop) then pcall(makefolder, drop); end;
        for i = 1, #dirs + 1 do
            local d = i > #dirs and drop or dirs[i];
            if d and isfolder(d) then
                local ok, fs = pcall(listfiles, d);
                if ok then
                    for _, p in fs do
                        local n = p:match("([^\\/]+)%.json$");
                        if n and not lg.found[n] then
                            lg.found[n] = p;
                            v[#v + 1] = n;
                            lg.names[#lg.names + 1] = n;
                        end;
                    end;
                end;
            end;
        end;
        return v;
    end;

    function lg.count()
        return #lg.names;
    end;

    function lg.decode(txt)
        if type(txt) ~= "string" then return nil, "nothing to read"; end;
        txt = txt:gsub("^%s+", ""):gsub("%s+$", "");
        if txt == "" then return nil, "nothing to read"; end;
        local ok, d = pcall(htp.JSONDecode, htp, txt);
        if not (ok and type(d) == "table") then return nil, "not valid json"; end;
        local objs = type(d.objects) == "table" and d.objects or (type(d[1]) == "table" and d[1].idx and d or nil);
        if not objs then return nil, "not an old config"; end;
        return objs;
    end;

    function lg.read(p)
        if not (isfile and readfile and p and p ~= "") then return nil, "no filesystem"; end;
        if not isfile(p) then return nil, "file not found"; end;
        local ok, txt = pcall(readfile, p);
        if not (ok and type(txt) == "string") then return nil, "unreadable"; end;
        return lg.decode(txt);
    end;

    local function run(objs)
        local out, hit, miss = lg.convert(objs);
        if not out then return nil, "menu not ready"; end;
        return { applied = lg.apply(out), mapped = hit, dropped = miss };
    end;

    function lg.import(p)
        local objs, why = lg.read(p);
        if not objs then return nil, why; end;
        return run(objs);
    end;

    function lg.importtext(txt)
        local objs, why = lg.decode(txt);
        if not objs then return nil, why; end;
        return run(objs);
    end;

    function lg.path(n)
        return lg.found[n];
    end;

    return lg;
end;

end)();
local _M26 = (function()
return function(ctx)
    local s, opt = ctx.svc, ctx.opt;
    local vim = s.vim;
    local sti = setthreadidentity or setidentity;
    local pn = { notes = nil, groups = {}, total = 0, playing = false, paused = false, tok = 0, t0 = 0, pt = 0, held = 0 };

    local kmap = {
        [36] = { "One", false }, [37] = { "One", true }, [38] = { "Two", false }, [39] = { "Two", true },
        [40] = { "Three", false }, [41] = { "Four", false }, [42] = { "Four", true },
        [43] = { "Five", false }, [44] = { "Five", true }, [45] = { "Six", false }, [46] = { "Six", true },
        [47] = { "Seven", false }, [48] = { "Eight", false }, [49] = { "Eight", true },
        [50] = { "Nine", false }, [51] = { "Nine", true }, [52] = { "Zero", false },
        [53] = { "Q", false }, [54] = { "Q", true }, [55] = { "W", false }, [56] = { "W", true },
        [57] = { "E", false }, [58] = { "E", true }, [59] = { "R", false },
        [60] = { "T", false }, [61] = { "T", true }, [62] = { "Y", false }, [63] = { "Y", true },
        [64] = { "U", false }, [65] = { "I", false }, [66] = { "I", true },
        [67] = { "O", false }, [68] = { "O", true }, [69] = { "P", false }, [70] = { "P", true },
        [71] = { "A", false }, [72] = { "S", false }, [73] = { "S", true },
        [74] = { "D", false }, [75] = { "D", true }, [76] = { "F", false },
        [77] = { "G", false }, [78] = { "G", true }, [79] = { "H", false }, [80] = { "H", true },
        [81] = { "J", false }, [82] = { "J", true }, [83] = { "K", false },
        [84] = { "L", false }, [85] = { "L", true }, [86] = { "Z", false }, [87] = { "Z", true },
        [88] = { "X", false }, [89] = { "C", false }, [90] = { "C", true },
        [91] = { "V", false }, [92] = { "V", true }, [93] = { "B", false }, [94] = { "B", true },
        [95] = { "N", false }, [96] = { "M", false }
    };

    function pn.dir()
        local l = ctx.lib;
        return ((l and l.dir) or "XenonHubJJSV10") .. "/MIDI Songs";
    end;

    function pn.mk()
        if not (isfolder and makefolder) then return false; end;
        local d = pn.dir();
        if not isfolder(d) then pcall(makefolder, d); end;
        return isfolder(d);
    end;

    function pn.list()
        local t = {};
        if not (listfiles and pn.mk()) then return t; end;
        local ok, fs = pcall(listfiles, pn.dir());
        if not ok then return t; end;
        for _, p in fs do
            local n = p:match("([^\\/]+%.[Mm][Ii][Dd][Ii]?)$");
            if n then t[#t + 1] = n; end;
        end;
        table.sort(t);
        return t;
    end;

    function pn.fetch(url, nm)
        if type(url) ~= "string" then return false, "no link"; end;
        url = url:gsub("^%s+", ""):gsub("%s+$", "");
        if url == "" then return false, "no link"; end;
        if not (writefile and pn.mk()) then return false, "no file access"; end;
        if sti then pcall(sti, 8); end;
        local ok, d = pcall(game.HttpGet, game, url);
        if not (ok and type(d) == "string" and d ~= "") then return false, "download failed"; end;
        if d:sub(1, 4) ~= "MThd" then return false, "link is not a midi file"; end;
        nm = nm and nm:gsub("^%s+", ""):gsub("%s+$", "") or "";
        if nm == "" then nm = url:match("([^/\\?#]+)%.[Mm][Ii][Dd][Ii]?") or "song"; end;
        nm = nm:gsub("%.[Mm][Ii][Dd][Ii]?$", ""):gsub('[<>:"/\\|%?%*]', "");
        if nm == "" then nm = "song"; end;
        nm = nm .. ".mid";
        if not pcall(writefile, pn.dir() .. "/" .. nm, d) then return false, "write failed"; end;
        return true, nm;
    end;

    local function vlq(d, p)
        local v, b = 0, 0;
        repeat
            b = d:byte(p);
            p += 1;
            v = v * 128 + b % 128;
        until b < 128;
        return v, p;
    end;
    local function u16(d, p) return d:byte(p) * 256 + d:byte(p + 1), p + 2; end;
    local function u32(d, p) return d:byte(p) * 16777216 + d:byte(p + 1) * 65536 + d:byte(p + 2) * 256 + d:byte(p + 3), p + 4; end;

    function pn.parse(d)
        if type(d) ~= "string" or d:sub(1, 4) ~= "MThd" then return nil, "not a midi file"; end;
        local p = 5;
        local hl, _, ntr, div;
        hl, p = u32(d, p);
        _, p = u16(d, p);
        ntr, p = u16(d, p);
        div, p = u16(d, p);
        if div >= 32768 then return nil, "smpte timing unsupported"; end;
        if hl > 6 then p += hl - 6; end;

        local ev, tm = {}, {};
        for _ = 1, ntr do
            if d:sub(p, p + 3) ~= "MTrk" then break; end;
            p += 4;
            local tl; tl, p = u32(d, p);
            local fin = p + tl;
            local at, last = 0, 0;
            while p < fin do
                local dt; dt, p = vlq(d, p);
                at += dt;
                local c = d:byte(p);
                if c < 128 then c = last; else p += 1; last = c; end;
                local hi = c // 16;
                if c == 255 then
                    local mt = d:byte(p); p += 1;
                    local ml; ml, p = vlq(d, p);
                    if mt == 81 and ml == 3 then
                        tm[#tm + 1] = { at, d:byte(p) * 65536 + d:byte(p + 1) * 256 + d:byte(p + 2) };
                    end;
                    p += ml;
                elseif c == 240 or c == 247 then
                    local sl; sl, p = vlq(d, p);
                    p += sl;
                elseif hi == 9 or hi == 8 then
                    local n, v = d:byte(p), d:byte(p + 1);
                    p += 2;
                    ev[#ev + 1] = { at, (hi == 9 and v > 0) and n or -n };
                elseif hi == 10 or hi == 11 or hi == 14 then p += 2;
                elseif hi == 12 or hi == 13 then p += 1;
                else p += 1; end;
            end;
            p = fin;
        end;

        table.sort(tm, function(a, b) return a[1] < b[1]; end);
        local marks, ct, lt, cs = { { 0, 0, 500000 } }, 500000, 0, 0;
        for _, m in tm do
            if m[1] > lt then
                cs += (m[1] - lt) * ct / (div * 1e6);
                lt = m[1];
            end;
            ct = m[2];
            marks[#marks + 1] = { lt, cs, ct };
        end;
        local function secs(tk)
            local m = marks[1];
            for i = #marks, 1, -1 do
                if marks[i][1] <= tk then m = marks[i]; break; end;
            end;
            return m[2] + (tk - m[1]) * m[3] / (div * 1e6);
        end;

        table.sort(ev, function(a, b)
            if a[1] ~= b[1] then return a[1] < b[1]; end;
            return a[2] < b[2];
        end);
        local out, open = {}, {};
        for _, e in ev do
            local n = e[2];
            if n > 0 then
                local o = { t = secs(e[1]), n = n, d = .14 };
                out[#out + 1] = o;
                open[n] = o;
            else
                local o = open[-n];
                if o then
                    o.d = math.max(secs(e[1]) - o.t, .06);
                    open[-n] = nil;
                end;
            end;
        end;
        table.sort(out, function(a, b) return a.t < b.t; end);
        if #out == 0 then return nil, "no notes in file"; end;
        return out;
    end;

    local function chords(ns)
        local g, c = {}, nil;
        for _, n in ns do
            if not c or n.t - c.t > .005 then
                c = { t = n.t, keys = {} };
                g[#g + 1] = c;
            end;
            c.keys[#c.keys + 1] = n.n;
        end;
        return g;
    end;

    function pn.load(nm)
        if not (nm and nm ~= "" and nm ~= "None" and isfile and readfile) then return false, "no file"; end;
        local p = pn.dir() .. "/" .. nm;
        if not isfile(p) then return false, "file not found"; end;
        local ok, d = pcall(readfile, p);
        if not ok then return false, "read failed"; end;
        local ns, why = pn.parse(d);
        if not ns then return false, why; end;
        pn.stop();
        pn.notes = ns;
        pn.groups = chords(ns);
        pn.total = ns[#ns].t + (ns[#ns].d or 0);
        pn.name = nm;
        return true, ns;
    end;

    function pn.elapsed()
        if not pn.playing then return 0; end;
        local base = pn.paused and pn.pt or tick();
        local sp = tonumber(opt("PianoSpeed", 1)) or 1;
        return math.min((base - pn.t0 - pn.held) * sp, pn.total);
    end;

    local function tap(keys)
        local plain, sharp = {}, {};
        local tr = math.floor(tonumber(opt("PianoTrans", 0)) or 0);
        for _, n in keys do
            local m = n + tr;
            while m < 36 do m += 12; end;
            while m > 96 do m -= 12; end;
            local k = kmap[m];
            if k then
                local t = k[2] and sharp or plain;
                t[#t + 1] = k[1];
            end;
        end;
        for _, k in plain do vim:SendKeyEvent(true, k, false, game); end;
        for _, k in plain do vim:SendKeyEvent(false, k, false, game); end;
        if #sharp == 0 then return; end;
        vim:SendKeyEvent(true, "LeftShift", false, game);
        for _, k in sharp do vim:SendKeyEvent(true, k, false, game); end;
        for _, k in sharp do vim:SendKeyEvent(false, k, false, game); end;
        vim:SendKeyEvent(false, "LeftShift", false, game);
    end;

    function pn.stop()
        pn.tok += 1;
        pn.playing, pn.paused, pn.held = false, false, 0;
    end;

    function pn.pause()
        if not pn.playing then return; end;
        if pn.paused then
            pn.held += tick() - pn.pt;
            pn.paused = false;
        else
            pn.pt = tick();
            pn.paused = true;
        end;
        return pn.paused;
    end;

    function pn.play()
        if not pn.notes or pn.playing then return false; end;
        local mute = opt("PianoMute", false) == true;
        pn.t0, pn.held = tick(), 0;
        pn.playing, pn.paused = true, false;
        pn.tok += 1;
        local mine = pn.tok;
        task.spawn(function()
            if sti then pcall(sti, 8); end;
            local i = 1;
            while pn.playing and mine == pn.tok and i <= #pn.groups do
                if pn.paused then
                    task.wait(.05);
                else
                    local e, g = pn.elapsed(), pn.groups[i];
                    if e >= g.t then
                        if not mute then tap(g.keys); end;
                        i += 1;
                    else
                        local sp = math.max(tonumber(opt("PianoSpeed", 1)) or 1, .01);
                        local w = (g.t - e) / sp;
                        task.wait(w > .05 and math.min(w - .03, .25) or 0);
                    end;
                end;
            end;
            if mine == pn.tok then pn.playing = false; end;
        end);
        return true;
    end;

    return pn;
end;

end)();
local _M27 = (function()
return function(ctx)
    local s, ut, opt = ctx.svc, ctx.ut, ctx.opt;
    local fy = { want = false };
    local uis, runs = s.uis, s.runs;

    local function pick(root, ...)
        local n = root;
        for _, k in { ... } do
            n = n and n:FindFirstChild(k);
        end;
        return n;
    end;

    local rush = pick(s.animfld, "Itadori", "Rush");
    local wind = pick(s.rs, "Utils", "Naoya", "FlyWind");
    local loop = pick(s.rs, "Sounds", "Megumi", "Serpent", "Fly");
    local boom = pick(s.rs, "Sounds", "Naoya", "TopSpeed", "SonicBoom");

    local hover = Instance.new("Animation");
    hover.AnimationId = "rbxassetid://96310332498648";

    local ctrl;
    pcall(function()
        local ps = s.lp:FindFirstChild("PlayerScripts");
        local pm = ps and ps:WaitForChild("PlayerModule", 5);
        ctrl = pm and require(pm):GetControls();
    end);

    local KB, KS = Enum.KeyCode.LeftControl, Enum.KeyCode.LeftAlt;
    local KW, KA, KSS, KD = Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D;
    local PRIO = Enum.AnimationPriority.Action4;
    local HUGE = Vector3.one * math.huge;

    local function lerp(a, b, t)
        return a + (b - a) * t;
    end;

    local function movevec()
        if ctrl then return ctrl:GetMoveVector(); end;
        local x, z = 0, 0;
        if uis:IsKeyDown(KW) then z -= 1; end;
        if uis:IsKeyDown(KSS) then z += 1; end;
        if uis:IsKeyDown(KA) then x -= 1; end;
        if uis:IsKeyDown(KD) then x += 1; end;
        return Vector3.new(x, 0, z);
    end;

    local on, bst, slw = false, false, false;
    local bv, bg, wfx, wnd, sfx, trk, idl, conn, dconn;
    local fov0, wfxon, boomed = 70, false, false;

    local function stop()
        if not on then return; end;
        on = false;
        bst, slw = false, false;
        if conn then conn:Disconnect(); conn = nil; end;
        if dconn then dconn:Disconnect(); dconn = nil; end;
        if trk then trk:Stop(.3); trk = nil; end;
        if idl then idl:Stop(.3); idl = nil; end;
        if bv then
            local rt = ut.hrp(s.lp.Character);
            if rt then rt.AssemblyLinearVelocity = bv.Velocity; end;
            bv:Destroy();
            bv = nil;
        end;
        if bg then bg:Destroy(); bg = nil; end;
        if wnd then wnd:Destroy(); wnd = nil; end;
        if sfx then sfx:Stop(); sfx:Destroy(); sfx = nil; end;
        wfx, wfxon, boomed = nil, false, false;
        workspace.CurrentCamera.FieldOfView = fov0;
        local ch = s.lp.Character;
        if not ch then return; end;
        local h = ch:FindFirstChildOfClass("Humanoid");
        if h then h.PlatformStand = false; end;
        local a = ch:FindFirstChild("Animate");
        if a then a.Disabled = false; end;
    end;

    local function start()
        if on then return true; end;
        local ch = s.lp.Character;
        local rt, h = ut.hrp(ch), ut.alive(ch);
        if not (rt and h) then return false; end;
        on = true;
        boomed, wfxon = false, false;

        local a = ch:FindFirstChild("Animate");
        if a then a.Disabled = true; end;
        h.PlatformStand = true;
        for _, t in ut.tracks(h) do t:Stop(.1); end;

        local anm = h:FindFirstChildOfClass("Animator");
        if rush then
            trk = anm and anm:LoadAnimation(rush) or h:LoadAnimation(rush);
            trk.Priority = PRIO;
        end;
        idl = anm and anm:LoadAnimation(hover) or h:LoadAnimation(hover);
        idl.Priority = PRIO;

        bv = Instance.new("BodyVelocity");
        bv.MaxForce = HUGE;
        bv.Velocity = rt.AssemblyLinearVelocity;
        bv.Parent = rt;

        bg = Instance.new("BodyGyro");
        bg.P, bg.D = 35000, 1200;
        bg.MaxTorque = HUGE;
        bg.CFrame = rt.CFrame;
        bg.Parent = rt;

        local cam = workspace.CurrentCamera;
        fov0 = cam.FieldOfView;

        if wind then
            wnd = wind:Clone();
            wfx = {};
            for _, v in wnd:GetDescendants() do
                if v:IsA("Trail") or v:IsA("ParticleEmitter") then
                    v.Enabled = false;
                    wfx[#wfx + 1] = v;
                end;
            end;
            wnd.Parent = cam;
        end;

        if loop then
            sfx = loop:Clone();
            sfx.Looped = true;
            sfx.Volume = 0;
            sfx.Parent = rt;
            sfx:Play();
        end;

        dconn = h.Died:Once(stop);

        conn = runs.RenderStepped:Connect(function()
            if not (on and rt.Parent and h.Parent) then return stop(); end;
            local cf = cam.CFrame;
            local mv = movevec();
            local dir = cf.LookVector * -mv.Z + cf.RightVector * mv.X;
            local mag = dir.Magnitude;
            local fast = bst or uis:IsKeyDown(KB);
            local slow = not fast and (slw or uis:IsKeyDown(KS));
            local spd = fast and opt("FlyBoost", 400) or (slow and opt("FlySlow", 80) or opt("FlySpeed", 180));

            if fast and mag > 0 then
                if not boomed and boom then
                    local b = boom:Clone();
                    b.Volume = .5;
                    b.Parent = rt;
                    b:Play();
                    s.debris:AddItem(b, 3);
                end;
                boomed = true;
            elseif not fast then
                boomed = false;
            end;

            if mag > 0 then
                local u = dir / mag;
                bv.Velocity = bv.Velocity:Lerp(u * spd, .12);
                bg.CFrame = bg.CFrame:Lerp(CFrame.lookAt(Vector3.zero, u) * CFrame.Angles(0, 0, math.rad(-cf.RightVector:Dot(u) * 35)), .1);
                if idl.IsPlaying then idl:Stop(.3); end;
                if trk then
                    if not trk.IsPlaying then trk:Play(.3); end;
                    trk.TimePosition = .67;
                    trk:AdjustSpeed(0);
                end;
                if wnd then
                    wnd.CFrame = CFrame.lookAlong(rt.Position, bv.Velocity);
                    if not wfxon then
                        for _, v in wfx do v.Enabled = true; end;
                        wfxon = true;
                    end;
                end;
                if sfx then
                    sfx.Volume = lerp(sfx.Volume, fast and 1.5 or .8, .1);
                    sfx.PlaybackSpeed = lerp(sfx.PlaybackSpeed, fast and 1.2 or .9, .1);
                end;
            else
                bv.Velocity = bv.Velocity:Lerp(Vector3.zero, .1);
                local lv = cf.LookVector;
                bg.CFrame = bg.CFrame:Lerp(CFrame.lookAt(Vector3.zero, Vector3.new(lv.X, 0, lv.Z)), .06);
                if trk and trk.IsPlaying then trk:Stop(.3); end;
                if not idl.IsPlaying then idl:Play(.3); end;
                if sfx then sfx.Volume = lerp(sfx.Volume, 0, .1); end;
                if wnd and wfxon then
                    for _, v in wfx do v.Enabled = false; end;
                    wfxon = false;
                end;
            end;

            cam.FieldOfView = lerp(cam.FieldOfView, fov0 + opt("FlyFov", 35) * (bv.Velocity.Magnitude / 400), .08);
        end);
        return true;
    end;

    function fy.set(v)
        fy.want = v == true;
        if not fy.want then
            stop();
            return true;
        end;
        return start();
    end;

    function fy.boost(v) bst = v == true; end;
    function fy.slow(v) slw = v == true; end;
    function fy.flying() return on; end;

    function fy.stop()
        fy.want = false;
        stop();
    end;

    ut.add(s.lp.CharacterRemoving:Connect(stop));
    ut.add(s.lp.CharacterAdded:Connect(function(ch)
        if not fy.want then return; end;
        ch:WaitForChild("HumanoidRootPart", 10);
        task.wait(.5);
        if fy.want then start(); end;
    end));

    return fy;
end;

end)();
local _M28 = (function()
return function(ctx)
    local s, ut, opt = ctx.svc, ctx.ut, ctx.opt;
    local pk = { on = false };
    local mc = s.movectrl;
    local gu = debug and rawget(debug, "getupvalues");
    local su = debug and rawget(debug, "setupvalue");
    local RUN, FALL = Enum.HumanoidStateType.Running, Enum.HumanoidStateType.Freefall;
    local JUMPST = Enum.HumanoidStateType.Jumping;
    local FLAT = Vector3.new(1, 0, 1);

    pk.ok = type(mc) == "table" and type(mc.Parkour) == "function";

    local rp;
    if pk.ok and type(gu) == "function" then
        local ok, ups = pcall(gu, mc.Parkour);
        if ok and type(ups) == "table" and typeof(ups[1]) == "RaycastParams" then rp = ups[1]; end;
    end;
    if not rp then
        rp = RaycastParams.new();
        rp.FilterType = Enum.RaycastFilterType.Include;
        local m = workspace:FindFirstChild("Map");
        rp.FilterDescendantsInstances = m and { m } or {};
    end;
    pk.rp = rp;

    local function jumps()
        if not (pk.ok and type(gu) == "function") then return 0; end;
        local ok, ups = pcall(gu, mc.Parkour);
        if ok and type(ups) == "table" and type(ups[2]) == "number" then return ups[2]; end;
        return 0;
    end;

    local function clearjumps()
        if pk.ok and type(su) == "function" then pcall(su, mc.Parkour, 2, 0); end;
    end;
    pk.jumps = jumps;
    pk.caninf = pk.ok and type(su) == "function";

    local iconn, iacc = nil, 0;

    function pk.setinf(v)
        if iconn then iconn:Disconnect(); iconn = nil; end;
        if v ~= true then return pk.caninf; end;
        if not pk.caninf then return false; end;
        iacc = 0;
        clearjumps();
        iconn = s.runs.Heartbeat:Connect(function(dt)
            iacc += dt;
            if iacc < .1 then return; end;
            iacc = 0;
            clearjumps();
        end);
        ut.add(iconn);
        return true;
    end;

    local function cap(ch, hum, info)
        local n = (info and info:FindFirstChild("DomainClash")) and 1
            or ((ch:GetAttribute("Moveset") ~= "Goku") and 3 or 4);
        local h, m = hum.Health, hum.MaxHealth;
        if h >= m * .33 then
            if h < m * .66 then n -= 1; end;
        else
            n -= 2;
        end;
        return n;
    end;

    local function scale(ch)
        local ok, v = pcall(function() return ch:GetScale(); end);
        return (ok and type(v) == "number" and v > 0) and v or 1;
    end;

    local conn, acc, lastw, lastst = nil, 0, 0, 0;

    local function side(pos, flat, sc)
        local r = flat.RightVector * sc;
        if workspace:Raycast(pos, r * 3, rp) then return 1; end;
        if workspace:Raycast(pos, r * -3, rp) then return -1; end;
        return 0;
    end;

    local function frame(ch, hrp)
        local cf = hrp.CFrame;
        local fv = cf.LookVector * FLAT;
        if fv.Magnitude < 1e-3 then return nil; end;
        return cf, CFrame.lookAlong(cf.Position, fv), scale(ch);
    end;

    pk.ticks, pk.why = 0, "idle";

    local function tick()
        pk.ticks += 1;
        if not pk.ok then pk.why = "nomc"; return; end;
        local ch = s.lp.Character;
        local hrp, hum = ut.hrp(ch), ut.alive(ch);
        if not (hrp and hum) then pk.why = "nochar"; return; end;
        if ch:GetAttribute("Movement") then pk.why = "busy"; return; end;
        local info = ch:FindFirstChild("Info");
        if info and (info:GetAttribute("Parkour") or info:FindFirstChild("NoParkour")) then pk.why = "cooldown"; return; end;

        local st = hum:GetState();
        local moving = hum.MoveDirection.Magnitude > .1;
        local wall = opt("PkWall", true) == true;
        local now = os.clock();

        if st == RUN then
            clearjumps();
            if opt("PkSprint", true) and moving and not ch:GetAttribute("Sprint") then
                ch:SetAttribute("Sprint", true);
            end;
            if opt("PkGround", true) == true and moving then
                pcall(mc.Parkour, mc, ch, hrp, hum);
            end;
            if not (wall and opt("PkStart", true) == true and moving) then pk.why = "run"; return; end;
            if now - lastst < .35 then pk.why = "startgap"; return; end;
            local cf, flat, sc = frame(ch, hrp);
            if not cf then pk.why = "nolook"; return; end;
            if side(cf.Position, flat, sc) == 0 then pk.why = "run.noside"; return; end;
            hum:ChangeState(JUMPST);
            hum.Jump = true;
            lastst = now;
            pk.why = "START";
            return;
        end;

        if st ~= FALL or not wall then pk.why = "state." .. tostring(st):gsub("Enum.HumanoidStateType.", ""); return; end;
        if now - lastw < (tonumber(opt("PkWallGap", .3)) or .3) then pk.why = "wallgap"; return; end;

        local cf, flat, sc = frame(ch, hrp);
        if not cf then pk.why = "nolook"; return; end;
        local pos = cf.Position;

        if workspace:Raycast(pos, flat.UpVector * (sc * 4), rp) then pk.why = "ceiling"; return; end;

        if opt("PkInfinite", false) ~= true and jumps() >= cap(ch, hum, info) then
            pk.why = "capped";
            return;
        end;

        local sd = side(pos, flat, sc);
        if sd == 0 then pk.why = "fall.noside"; return; end;

        local prev = hum.MoveDirection;
        hum:Move(cf.RightVector * sd, false);
        hum.Jump = true;
        pcall(mc.Parkour, mc, ch, hrp, hum);
        hum.Jump = false;
        hum:Move(prev, false);
        lastw = now;
        pk.why = "WALLJUMP";
    end;

    function pk.set(v)
        pk.on = v == true;
        if conn then conn:Disconnect(); conn = nil; end;
        if not pk.on then return pk.ok; end;
        if not pk.ok then return false; end;
        acc = 0;
        conn = s.runs.Heartbeat:Connect(function(dt)
            acc += dt;
            local gap = 1 / math.clamp(tonumber(opt("PkRate", 20)) or 20, 5, 60);
            if acc < gap then return; end;
            acc = 0;
            tick();
        end);
        ut.add(conn);
        return true;
    end;

    function pk.stop()
        pk.on = false;
        if conn then conn:Disconnect(); conn = nil; end;
        if iconn then iconn:Disconnect(); iconn = nil; end;
    end;

    return pk;
end;

end)();
local _M29 = (function()
return function(ctx)
    local s, ut, opt = ctx.svc, ctx.ut, ctx.opt;
    local rs = { on = false, count = 0 };
    local jre = s.knit:FindFirstChild("JoinService");
    jre = jre and jre:FindFirstChild("RE");
    local rem = jre and jre:FindFirstChild("Reset");
    rs.ok = rem ~= nil;

    local env = getfenv();
    local rsig = env.replicatesignal;
    rs.canbreak = type(rsig) == "function";

    local dc, hc, ac, busy, tok, last, born = nil, nil, nil, false, 0, 0, 0;
    local ncp = {};

    local function unclip()
        for p, v in next, ncp do
            if p.Parent then p.CanCollide = v; end;
        end;
        table.clear(ncp);
    end;

    local function clip(ch)
        table.clear(ncp);
        for _, v in ch:GetDescendants() do
            if v:IsA("BasePart") and v.CanCollide then
                ncp[v] = true;
                v.CanCollide = false;
            end;
        end;
    end;

    local function spoof(cf)
        local b = ctx.bypass;
        if b and b.ok and b.spoof then b.spoof(cf); end;
    end;

    local function slam(ch, hrp, hum, mine)
        local void = Vector3.new(0, tonumber(opt("RespVoid", 10000)) or 10000, 0);
        local dur = tonumber(opt("RespHold", .5)) or .5;
        clip(ch);
        spoof(hrp.CFrame);
        if opt("RespBreak", true) == true and rs.canbreak then
            pcall(rsig, hum.ServerBreakJoints);
        end;
        local t0 = os.clock();
        while os.clock() - t0 < dur do
            if mine ~= tok or not (hrp and hrp.Parent) then break; end;
            local real = hrp.CFrame;
            spoof(real);
            hrp.CFrame = CFrame.new(void);
            task.wait();
            if not (hrp and hrp.Parent) then break; end;
            hrp.CFrame = real;
        end;
        spoof(nil);
        unclip();
    end;

    local function go(ch, hrp, hum)
        if busy then return; end;
        local now = os.clock();
        if now - last < 1.5 then return; end;
        last = now;
        busy = true;
        tok += 1;
        local mine = tok;
        rs.count += 1;
        task.spawn(function()
            local d = tonumber(opt("RespDelay", 0)) or 0;
            if d > 0 then task.wait(d); end;
            if mine ~= tok then busy = false; return; end;
            if hrp and hrp.Parent and hum then
                local ok, err = pcall(slam, ch, hrp, hum, mine);
                if not ok then
                    spoof(nil);
                    unclip();
                    ut.warn("respawn", err);
                end;
            end;
            if mine == tok and rem then pcall(function() rem:FireServer(); end); end;
        end);
    end;

    local function died(ch, hrp, hum)
        if not rs.on then return; end;
        if os.clock() - born < 1.25 then return; end;
        if ch ~= s.lp.Character then return; end;
        go(ch, hrp, hum);
    end;

    local function bind(ch)
        if dc then dc:Disconnect(); dc = nil; end;
        if hc then hc:Disconnect(); hc = nil; end;
        busy = false;
        born = os.clock();
        if not ch then return; end;
        local hum = ch:FindFirstChildOfClass("Humanoid") or ch:WaitForChild("Humanoid", 5);
        local hrp = ch:FindFirstChild("HumanoidRootPart") or ch:WaitForChild("HumanoidRootPart", 5);
        if not (hum and hrp) then return; end;
        dc = hum.Died:Connect(function() died(ch, hrp, hum); end);
        hc = hum.HealthChanged:Connect(function(h)
            if h <= 0 then died(ch, hrp, hum); end;
        end);
    end;

    function rs.now()
        local ch = s.lp.Character;
        local hrp, hum = ut.hrp(ch), ch and ch:FindFirstChildOfClass("Humanoid");
        if not (hrp and hum) then return false; end;
        busy, last = false, 0;
        go(ch, hrp, hum);
        return true;
    end;

    function rs.set(v)
        rs.on = v == true;
        if not rs.on then
            tok += 1;
            busy = false;
            spoof(nil);
            unclip();
            if dc then dc:Disconnect(); dc = nil; end;
            if hc then hc:Disconnect(); hc = nil; end;
            if ac then ac:Disconnect(); ac = nil; end;
            return rs.ok;
        end;
        if not ac then
            ac = s.lp.CharacterAdded:Connect(function(ch) task.defer(bind, ch); end);
            ut.add(ac);
        end;
        bind(s.lp.Character);
        return true;
    end;

    function rs.stop()
        rs.on = false;
        tok += 1;
        busy = false;
        spoof(nil);
        unclip();
        if dc then dc:Disconnect(); dc = nil; end;
        if hc then hc:Disconnect(); hc = nil; end;
        if ac then ac:Disconnect(); ac = nil; end;
    end;

    return rs;
end;

end)();
local _M30 = (function()
return function(ctx)
    local s, ut = ctx.svc, ctx.ut;
    local fl = ctx.filter;
    local an = { ok = false, kinds = { "Block", "Counter", "Punish", "Multi", "Adapt", "Decisive" } };
    if not fl then return an; end;
    an.ok = true;

    local kfp = game:GetService("KeyframeSequenceProvider");
    local hs = game:GetService("HttpService");
    local animfld = s.animfld;
    local DIR = "XenonHubJJSV10";
    local FILE = DIR .. "/animfilter.json";

    local store, edited, base, orig = {}, {}, {}, {};
    an.store, an.edited = store, edited;

    local icache, hcache = {}, {};

    local function inst(path)
        local c = icache[path];
        if c ~= nil then return c or nil; end;
        local o = animfld;
        for part in path:gmatch("[^.]+") do
            o = o and o:FindFirstChild(part);
            if not o then break; end;
        end;
        local r = (o and o:IsA("Animation")) and o or false;
        icache[path] = r;
        return r or nil;
    end;
    an.inst = inst;

    local function nameof(path)
        return path:match("([^.]+)$") or path;
    end;
    an.nameof = nameof;

    local sets, setn = {}, 0;

    function an.sets()
        if setn == #fl.allpaths and #sets > 0 then return sets; end;
        local seen = {};
        table.clear(sets);
        for _, p in fl.allpaths do
            local st = p:match("^([^.]+)");
            if st and not seen[st] then seen[st] = true; sets[#sets + 1] = st; end;
        end;
        table.sort(sets);
        table.insert(sets, 1, "All");
        setn = #fl.allpaths;
        return sets;
    end;

    function an.paths(set, q, cap)
        local t = {};
        for _, p in fl.allpaths do
            if (not set or set == "All" or p:sub(1, #set + 1) == set .. ".") and (not q or q == "" or p:lower():find(q, 1, true)) then
                t[#t + 1] = p;
            end;
        end;
        table.sort(t);
        local n = cap or 260;
        for i = #t, n + 1, -1 do t[i] = nil; end;
        return t;
    end;

    local function kwblock(path)
        local chain = nameof(path):lower() .. "/" .. path:lower();
        for _, kw in fl.denykw do
            if chain:find(kw, 1, true) then return false; end;
        end;
        return true;
    end;
    an.kwblock = kwblock;

    local function tofl(ov, kb)
        local t = {};
        local blk;
        if ov.block ~= nil then blk = ov.block; else blk = kb; end;
        t[#t + 1] = {
            k = "Block", on = blk, b = 0, e = -1,
            rng = ov.range, hold = ov.holdextra,
            dr = ov.holdondoors and (ov.doorrange or 5) or nil,
            dt = ov.holdondoors and (ov.doortimeout or 6) or nil,
        };
        if ov.counter ~= nil or ov.ctrange or ov.ctwait then
            local f = { k = "Counter", on = ov.counter ~= false, b = 0, e = -1, rng = ov.ctrange };
            local w = ov.ctwait;
            if type(w) == "table" then
                f.at = math.sqrt(w.r2);
                f.wait = w.d;
                f.cls = w.cd;
                f.out = w.od;
            elseif w then
                f.wait = w;
            end;
            t[#t + 1] = f;
        end;
        t[#t + 1] = { k = "Punish", on = blk and ov.punish ~= false, b = 0, e = -1 };
        if ov.multi ~= nil then t[#t + 1] = { k = "Multi", on = ov.multi, b = 0, e = -1 }; end;
        if ov.adapt ~= nil then t[#t + 1] = { k = "Adapt", on = ov.adapt, b = 0, e = -1 }; end;
        if ov.decisive ~= nil then t[#t + 1] = { k = "Decisive", on = ov.decisive, b = 0, e = -1 }; end;
        return t;
    end;

    local function defaults(path)
        local d = base[path];
        if d then return d; end;
        d = fl.overrides[path];
        if not d then
            local nm = nameof(path);
            d = fl.overrides["@" .. nm:lower()] or fl.overrides[nm] or fl.overrides[nm:lower()];
        end;
        base[path] = d or false;
        return d;
    end;

    function an.flags(path)
        local f = store[path];
        if f then return f; end;
        local d = defaults(path);
        f = tofl(d or {}, kwblock(path));
        store[path] = f;
        return f;
    end;

    function an.blocks(path)
        for _, f in an.flags(path) do
            if f.k == "Block" then return f.on; end;
        end;
        return false;
    end;

    local function toov(flg)
        local o, win = {}, {};
        for _, f in flg do
            local k = f.k;
            win[#win + 1] = { k = k, on = f.on, b = f.b or 0, e = f.e or -1 };
            if k == "Block" then
                if o.block == nil or f.on then o.block = f.on; end;
                if f.rng then o.range = f.rng; end;
                if f.hold then o.holdextra = f.hold; end;
                if f.dr then
                    o.holdondoors = true;
                    o.doorrange = f.dr;
                    o.doortimeout = f.dt or 6;
                end;
            elseif k == "Counter" then
                if o.counter == nil or f.on then o.counter = f.on; end;
                if f.rng then o.ctrange = f.rng; end;
                if f.at then
                    o.ctwait = fl.enemy(f.at, { enter = f.wait or 0, close = f.cls, out = f.out });
                elseif f.wait then
                    o.ctwait = f.wait;
                elseif (f.b or 0) > 0 then
                    o.ctwait = f.b;
                end;
            elseif k == "Punish" then
                if o.punish == nil or f.on then o.punish = f.on; end;
            elseif k == "Multi" then
                if o.multi == nil or f.on then o.multi = f.on; end;
            elseif k == "Adapt" then
                if o.adapt == nil or f.on then o.adapt = f.on; end;
            elseif k == "Decisive" then
                if o.decisive == nil or f.on then o.decisive = f.on; end;
            end;
        end;
        if o.block == nil then o.block = false; end;
        o.win = win;
        return o;
    end;
    an.toov = toov;

    local rpend = false;

    local function sched()
        if rpend then return; end;
        rpend = true;
        task.delay(.25, function()
            rpend = false;
            pcall(fl.reapply);
        end);
    end;

    local function sibs(path)
        local nid = fl.pathids[path];
        local set = nid and fl.idpaths[nid];
        local t = { path };
        if set then
            table.clear(t);
            for q in set do t[#t + 1] = q; end;
            if #t == 0 then t[1] = path; end;
        end;
        return t;
    end;
    an.sibs = sibs;

    function an.commit(path, quiet)
        local f = store[path];
        if not f then return false; end;
        local ov = toov(f);
        for _, q in sibs(path) do
            if orig[q] == nil then orig[q] = fl.overrides[q] or false; end;
            fl.overrides[q] = ov;
            store[q] = f;
            edited[q] = true;
        end;
        if not quiet then sched(); end;
        return true;
    end;

    function an.revert(path)
        for _, q in sibs(path) do
            store[q] = nil;
            edited[q] = nil;
            local o = orig[q];
            if o ~= nil then
                fl.overrides[q] = o or nil;
                orig[q] = nil;
            end;
        end;
        pcall(fl.reapply);
        return true;
    end;

    function an.hits(path, cb)
        local a = inst(path);
        if not a then cb({}); return; end;
        local id = a.AnimationId;
        local c = hcache[id];
        if c then cb(c); return; end;
        task.spawn(function()
            local t = {};
            local ok, ks = pcall(function() return kfp:GetKeyframeSequenceAsync(id); end);
            if ok and ks then
                for _, m in ks:GetDescendants() do
                    if m:IsA("KeyframeMarker") and m.Name == "Function" and m.Value == "Hitbox" then
                        local kf = m.Parent;
                        if kf and kf:IsA("Keyframe") then t[#t + 1] = kf.Time; end;
                    end;
                end;
            end;
            table.sort(t);
            hcache[id] = t;
            cb(t);
        end);
    end;

    function an.count()
        local n = 0;
        for _ in edited do n += 1; end;
        return n;
    end;

    function an.save()
        if not (writefile and hs) then return false; end;
        if isfolder and makefolder then
            local ok, has = pcall(isfolder, DIR);
            if ok and not has then pcall(makefolder, DIR); end;
        end;
        local ok, txt = pcall(hs.JSONEncode, hs, pack());
        if not ok then return false; end;
        return (pcall(writefile, FILE, txt));
    end;

    local function wipe()
        for p in edited do
            store[p] = nil;
            local o = orig[p];
            fl.overrides[p] = (o ~= nil and o) or nil;
            orig[p] = nil;
        end;
        table.clear(edited);
    end;

    local function pack()
        local out = {};
        for p in edited do
            local f = store[p];
            if f then out[p] = f; end;
        end;
        return out;
    end;

    local function unpack(t)
        wipe();
        local n = 0;
        for p, f in t do
            if type(f) == "table" then
                store[p] = f;
                edited[p] = true;
                an.commit(p, true);
                n += 1;
            end;
        end;
        pcall(fl.reapply);
        an.loaded = n;
        return n;
    end;

    local function readjson(path)
        if not (readfile and isfile and hs) then return nil; end;
        local ok, has = pcall(isfile, path);
        if not (ok and has) then return nil; end;
        local ok2, txt = pcall(readfile, path);
        if not ok2 then return nil; end;
        local ok3, d = pcall(hs.JSONDecode, hs, txt);
        if not (ok3 and type(d) == "table") then return nil; end;
        return d;
    end;

    function an.tocfg(path)
        local d = readjson(path);
        if not (d and writefile) then return false; end;
        d.animfilter = pack();
        local ok, enc = pcall(hs.JSONEncode, hs, d);
        if not ok then return false; end;
        return (pcall(writefile, path, enc));
    end;

    function an.fromcfg(path)
        local d = readjson(path);
        if not d then return false; end;
        local t = d.animfilter;
        if type(t) ~= "table" then return false; end;
        return true, unpack(t);
    end;

    function an.load()
        local d = readjson(FILE);
        if not d then return false; end;
        return true, unpack(d);
    end;

    function an.clear()
        wipe();
        pcall(fl.reapply);
        if delfile and isfile then
            local ok, has = pcall(isfile, FILE);
            if ok and has then pcall(delfile, FILE); end;
        end;
    end;

    function an.stop() end;

    if fl.ready then
        task.spawn(an.load);
    else
        local prev = fl.onready;
        fl.onready = function()
            if prev then pcall(prev); end;
            task.spawn(an.load);
        end;
    end;

    return an;
end;

end)();
local _M31 = (function()
return function(ctx)
    local bf, fl, tk, bk, lk, ms = ctx.bfc, ctx.filter, ctx.track, ctx.block, ctx.lock, ctx.misc;
    local caps, ut, mo, sa, co, ar = ctx.caps, ctx.ut, ctx.mobile, ctx.sda, ctx.combo, ctx.aura;
    local iv, vo, avm, bbk, lgc, pia, byp, fy = ctx.invis, ctx.vote, ctx.avatar, ctx.bbreak, ctx.legacy, ctx.piano, ctx.bypass, ctx.fly;
    local pkr, rsp, af = ctx.parkour, ctx.respawn, ctx.animf;
    local DIR = "XenonHubJJSV10";
    
    
    
    local UIURL = "";

    local function get(u)
        if type(game.HttpGet) == "function" then
            local ok, r = pcall(game.HttpGet, game, u);
            if ok and type(r) == "string" then return r; end;
        end;
        local rq = request;
        if type(rq) == "function" then
            local ok, r = pcall(rq, { Url = u, Method = "GET" });
            if ok and type(r) == "table" and type(r.Body) == "string" then return r.Body; end;
        end;
    end;

    
    
    
    local function fetchui()
        local why = "not reachable";
        
        for pass = 1, 2 do
            local r = get(UIURL);
            if type(r) == "string" and #r > 20000 and r:find("return lib", #r - 200, true) then return r; end;
            if type(r) == "string" then
                why = #r .. " byte reply from " .. (UIURL:match("//([^/]+)") or UIURL);
            end;
            if pass == 1 then task.wait(.5); end;
        end;
        return nil, why;
    end;

    local src, why = fetchui();
    if not src then error("interface download failed (" .. tostring(why) .. ")", 0); end;
    local mk, cerr = loadstring(src, "PotentUI");
    if not mk then error("interface failed to compile: " .. tostring(cerr), 0); end;

    local lib = mk();
    ctx.lib = lib;
    ctx.cfg.bind(lib.flags);

    local function dp(v)
        local d = tostring(v):match("%.(%d+)");
        return d and #d or 0;
    end;

    local function sl(s, o)
        o.Round = dp(o.Step or 1);
        return s:Slider(o);
    end;

    local function note(t, d, i)
        lib:Notify({ Title = t, Text = d, Icon = i, Time = 5 });
    end;

    local sv = ctx.svc;
    local function plrvals()
        local v = { "None" };
        for _, p in sv.plrs:GetPlayers() do
            if p ~= sv.lp then v[#v + 1] = p.Name; end;
        end;
        table.sort(v, function(a, b)
            if a == "None" then return true; end;
            if b == "None" then return false; end;
            return a < b;
        end);
        return v;
    end;

    local function tgtdd(g, flag)
        local d = g:Dropdown({ Name = "Selected Target", Flag = flag, Values = plrvals(), Default = "None", Search = true });
        ut.add(sv.plrs.PlayerAdded:Connect(function() d:SetValues(plrvals(), true); end));
        ut.add(sv.plrs.PlayerRemoving:Connect(function(p)
            if lib.flags[flag] == p.Name then d:Set("None", true); end;
            d:SetValues(plrvals(), true);
        end));
        return d;
    end;

    local win = lib:Window({
        Title = "Xenon Hub",
        Icon = "https://raw.githubusercontent.com/Synergay/videos/main/margo.png",
        Size = Vector2.new(900, 600),
        Key = Enum.KeyCode.RightShift,
        Folder = DIR,
    });

    local home = win:Tab({ Name = "Home", Icon = "home", Desc = "status and key" });

    win:Category("Combat");
    local abp = win:Tab({ Name = "Auto Block", Icon = "shield", Desc = "block, punish and counter" });
    local bfp = win:Tab({ Name = "Dash Assist/BFC", Icon = "zap", Desc = "black flash chain and side dash" });
    local cbp = win:Tab({ Name = "Combat", Icon = "swords", Desc = "character autos and hitbox" });
    local ep = win:Tab({ Name = "ESP", Icon = "eye", Desc = "see players through walls" });
    local afp = (af and af.ok) and win:Tab({ Name = "Anim Filter", Icon = "film", Desc = "per animation timing" }) or nil;

    win:Category("Aim");
    local prp = win:Tab({ Name = "Lock On", Icon = "crosshair", Desc = "tracking and lock on" });

    win:Category("Combo");
    local cmb = win:Tab({ Name = "Auto Combo", Icon = "code", Desc = "one command per line" });

    win:Category("Player");
    local msp = win:Tab({ Name = "Misc", Icon = "wrench", Desc = "movement, utility and mobile" });
    local aup = win:Tab({ Name = "Aura/Music", Icon = "sparkles", Desc = "recolour effects and swap sounds" });
    local pip = pia and win:Tab({ Name = "Auto Piano", Icon = "music", Desc = "midi to roblox piano" });

    local ky = ctx.key;
    local KEYURL = "https://ads.luarmor.net/get_key?for=JJS_6_Hours-OHrDCAoiiCnv";
    local UNAME = sv.lp.Name;
    local DNAME = sv.lp.DisplayName or sv.lp.Name;
    local AVATAR = "rbxthumb://type=AvatarHeadShot&id=" .. sv.lp.UserId .. "&w=150&h=150";

    local function getkey()
        local opened = pcall(function() game:GetService("GuiService"):OpenBrowserWindow(KEYURL); end);
        local copied = false;
        if setclipboard then
            local an = ctx.anti;
            if an and an.mute then an.mute(true); end;
            copied = pcall(setclipboard, KEYURL);
            if an and an.mute then task.defer(an.mute, false); end;
        end;
        note("Key", opened and "opened in your browser" or (copied and "link copied to clipboard" or KEYURL), "key-round");
    end;

    local HSEC = home:Section({ Name = "Overview", Full = true });
    local HD = HSEC:Group({ Bare = true });

    
    
    
    local btnreg = {};
    do
        local gm = getmetatable(HD);
        if type(gm) == "table" and type(gm.Button) == "function" then
            local old = gm.Button;
            gm.Button = function(g, o)
                local r = old(g, o);
                if type(o) == "table" and o.Name and o.Callback then
                    local sc = g.sec;
                    local tb = sc and sc.tab;
                    btnreg[#btnreg + 1] = { nm = o.Name, cb = o.Callback, tab = tb and tb.name or nil };
                end;
                return r;
            end;
        end;
    end;
    local hero = HD:Hero({
        Title = "WELCOME " .. string.upper(DNAME),
        Sub = "@" .. UNAME,
        Image = AVATAR
    });

    local function hname()
        if lib.flags.HideUser == true then return "WELCOME *********", "@*********"; end;
        return "WELCOME " .. string.upper(DNAME), "@" .. UNAME;
    end;

    local tiles = HD:Stats({
        { Name = "Feature Count", Value = "0", Icon = "layers" },
        { Name = "Ping", Value = "0 ms", Icon = "activity" },
        { Name = "FPS", Value = "0", Icon = "gauge" },
        { Name = "Animations", Value = "0", Icon = "film" },
    });
    local hp, hf, ha = tiles[2], tiles[3], tiles[4];

    local ktiles = HD:Stats({
        { Name = "Key Status", Value = "-", Icon = "key-round" },
        { Name = "Expires", Value = "-", Icon = "calendar-clock" },
        { Name = "Executions", Value = "-", Icon = "play" },
    });

    local HK = HSEC:Group({ Name = "Session", Side = 1 });

    local function kdraw()
        local ok, pend = ky.ok(), ky.code == "UNCHECKED";
        ktiles[1]:Set(ky.label());
        ktiles[1]:SetColor(ok and lib.theme.ok or (pend and lib.theme.amber or lib.theme.warn));
        ktiles[2]:Set(ky.expiry());
        ktiles[3]:Set(ky.runs());
    end;

    local function kcheck()
        ky.code = "UNCHECKED";
        kdraw();
        task.spawn(function()
            ky.check();
            kdraw();
            if not ky.ok() and ky.code ~= "NO_SCRIPT_ID" and ky.code ~= "FREE" then
                note("Key", ky.label(), "key-round");
            end;
        end);
    end;

    HK:Toggle({ Name = "Hide Username", Flag = "HideUser", Default = false, Callback = function(v)
        hero:Set(hname());
        lib:Mask(v);
    end });
    HK:Divider();
    HK:Button({ Name = "Get Key", Callback = getkey });
    HK:Button({ Name = "Recheck", Callback = kcheck });
    HK:Divider();
    HK:Button({ Name = "Randomise Picture", Callback = function()
        hero:SetImage("rbxthumb://type=AvatarHeadShot&id=" .. math.random(1, 9e7) .. "&w=150&h=150");
    end });
    HK:Button({ Name = "Restore Picture", Callback = function() hero:SetImage(AVATAR); end });

    kcheck();

    local BFC = bfp:Section("BFC");
    local L = BFC:Group({ Name = "Chain", Side = 1 });
    local LB = BFC:Group({ Name = "Aim", Side = 1 });
    local RC = BFC:Group({ Name = "Arc", Side = 2 });
    local RP = BFC:Group({ Name = "Positioning", Side = 2 });

    local chaint = L:Toggle({ Name = "Enable Chain", Flag = "BFCEnabled", Default = false, Callback = function(v)
        if v then bf.start(); else bf.stop(); end;
    end });
    chaint:Keybind({ Flag = "BFCChainKey", Mode = "Toggle" });
    L:Toggle({ Name = "Auto Black Flash", Flag = "AutoBlackFlash", Default = false, Callback = function(v)
        if not v then bf.abfstop(); return; end;
        if not bf.abfstart() then note("Black Flash", "Effects remote missing", "zap"); end;
    end });
    L:Toggle({ Name = "No Stick", Flag = "DFArcNoStick", Default = false });
    L:Toggle({ Name = "Auto Feint", Flag = "AutoFeintBFC", Default = false });
    L:Divider();
    L:Button({ Name = "Manual Black Flash", Callback = function() bf.manual(); end });
    L:Keybind({ Name = "Manual Key", Flag = "BFCKey", Mode = "Hold", Callback = function(v)
        if v then bf.manual(); end;
    end });

    LB:Toggle({ Name = "Auto Angle", Flag = "DFArcAutoAngle", Default = false });
    LB:Toggle({ Name = "Static Angle", Flag = "DFArcAngle", Default = false });

    RC:Toggle({ Name = "Customize Arc", Flag = "BFCCustomize", Default = false });
    RC:Toggle({ Name = "Curve", Flag = "BFCCurve", Default = false });
    RC:Dropdown({ Name = "Curve Type", Flag = "BFCCurveType", Values = { "Linear", "Ease-In", "Ease-Out", "Ease-In-Out" }, Default = "Ease-Out" });
    RC:Toggle({ Name = "Cycle Curve", Flag = "BFCCycleCurve", Default = false });
    RC:Toggle({ Name = "Curve Affects Dash", Flag = "BFCCurveDash", Default = false });

    RP:Toggle({ Name = "Lock Arc Point", Flag = "BFCLockArc", Default = false });
    RP:Toggle({ Name = "Backflip BFC", Flag = "BFCBackflip", Default = false });
    RP:Toggle({ Name = "Predict Back", Flag = "BFCBackPred", Default = false });
    RP:Toggle({ Name = "Arc Over Target", Flag = "BFCArcOver", Default = false });

    local BFV = bfp:Section("BFC Values");
    local VC = BFV:Group({ Name = "Chain", Side = 1 });
    local VP = BFV:Group({ Name = "Positioning", Side = 1 });
    local VA = BFV:Group({ Name = "Arc", Side = 2 });
    local VU = BFV:Group({ Name = "Curve", Side = 2 });

    sl(VC, { Name = "Range", Flag = "DFArcDist", Min = 5, Max = 60, Default = 30, Step = 1, Suffix = " studs" });
    sl(VC, { Name = "Manual Delay", Flag = "DFArcDelay", Min = .1, Max = 1.2, Default = .4, Step = .01, Suffix = "s" });
    sl(VC, { Name = "Cooldown", Flag = "BFCCooldown", Min = .1, Max = 3, Default = .8, Step = .01, Suffix = "s" });
    sl(VC, { Name = "BF Delay", Flag = "ABFDelay", Min = 0, Max = .5, Default = .1, Step = .01, Suffix = "s" });
    sl(VC, { Name = "Angle", Flag = "DFArcAngleVal", Min = -45, Max = 45, Default = 15, Step = 1, Suffix = "°" });

    sl(VP, { Name = "Back Pred Strength", Flag = "BFCBackPredStrength", Min = 0, Max = 2, Default = 1, Step = .01 });
    sl(VP, { Name = "Arc Height", Flag = "BFCArcHeight", Min = 4, Max = 30, Default = 12, Step = .5, Suffix = " studs" });

    sl(VA, { Name = "Radius", Flag = "BFCArcRadius", Min = 2, Max = 15, Default = 5, Step = .1, Suffix = " studs" });
    sl(VA, { Name = "Duration", Flag = "BFCArcDuration", Min = .15, Max = 1, Default = .4, Step = .01, Suffix = "s" });
    sl(VA, { Name = "Max Speed", Flag = "BFCMaxArcSpeed", Min = 40, Max = 250, Default = 120, Step = 1 });
    sl(VA, { Name = "Dash Mult Cap", Flag = "BFCDashMultCap", Min = .5, Max = 3, Default = 1.5, Step = .01 });
    sl(VA, { Name = "Correction Speed", Flag = "BFCCorrectionSpeed", Min = 50, Max = 300, Default = 150, Step = 1 });

    sl(VU, { Name = "Curve Power", Flag = "BFCCurvePow", Min = 1, Max = 8, Default = 3, Step = .1 });
    sl(VU, { Name = "Curve Floor", Flag = "BFCCurveFloor", Min = .01, Max = .5, Default = .08, Step = .01 });

    if sa then
        local SDA = bfp:Section("Side Dash");
        local SD = SDA:Group({ Name = "Side Dash Assist", Side = 1 });
        local SDT = SDA:Group({ Name = "Targeting", Side = 1 });
        local SDC = SDA:Group({ Name = "Arc", Side = 2 });
        local SDP = SDA:Group({ Name = "Positioning", Side = 2 });

        local sdat = SD:Toggle({ Name = "Enabled", Flag = "SDAOn", Default = false });
        sdat:Keybind({ Flag = "SDAKey", Mode = "Toggle" });
        SD:Toggle({ Name = "No Stick", Flag = "SDANoStick", Default = false });
        SD:Divider();
        SD:Button({ Name = "Side Dash", Callback = function() sa.fire(); end });
        SD:Keybind({ Name = "Dash Key", Flag = "SDAFireKey", Mode = "Hold", Callback = function(v)
            if v then sa.fire(); end;
        end });

        SDT:Toggle({ Name = "Only Locked Target", Flag = "SDAOnlyLocked", Default = false });
        SDT:Toggle({ Name = "Only Selected Target", Flag = "SDAOnlySelected", Default = false });
        SDT:Toggle({ Name = "Lock While Dashing", Flag = "SDALock", Default = false });
        SDT:Toggle({ Name = "Punish After Dash", Flag = "SDAPunish", Default = false });
        tgtdd(SDT, "SDATarget");

        SDC:Toggle({ Name = "Customize Arc", Flag = "SDACustomize", Default = false });
        SDC:Toggle({ Name = "Curve", Flag = "SDACurve", Default = false });
        SDC:Dropdown({ Name = "Curve Type", Flag = "SDACurveType", Values = { "Linear", "Ease-In", "Ease-Out", "Ease-In-Out" }, Default = "Ease-Out" });
        SDC:Toggle({ Name = "Cycle Curve", Flag = "SDACycleCurve", Default = false });
        SDC:Toggle({ Name = "Curve Affects Dash", Flag = "SDACurveDash", Default = false });

        SDP:Toggle({ Name = "Lock Arc Point", Flag = "SDALockArc", Default = false });
        SDP:Toggle({ Name = "Backflip", Flag = "SDABackflip", Default = false });
        SDP:Toggle({ Name = "Predict Back", Flag = "SDABackPred", Default = false });
        SDP:Toggle({ Name = "Arc Over Target", Flag = "SDAArcOver", Default = false });

        local SDV = bfp:Section("SDA Values");
        local SVC = SDV:Group({ Name = "Core", Side = 1 });
        local SVP = SDV:Group({ Name = "Positioning", Side = 1 });
        local SVA = SDV:Group({ Name = "Arc", Side = 2 });
        local SVU = SDV:Group({ Name = "Curve", Side = 2 });

        sl(SVC, { Name = "Range", Flag = "SDADist", Min = 5, Max = 60, Default = 30, Step = 1, Suffix = " studs" });
        sl(SVC, { Name = "Cooldown", Flag = "SDACd", Min = .1, Max = 3, Default = .5, Step = .01, Suffix = "s" });
        sl(SVC, { Name = "Punish Timing", Flag = "SDAPunishT", Min = .01, Max = 1, Default = .12, Step = .01, Suffix = "s" });

        sl(SVP, { Name = "Back Pred Strength", Flag = "SDABackPredStrength", Min = 0, Max = 2, Default = 1, Step = .01 });
        sl(SVP, { Name = "Arc Height", Flag = "SDAArcHeight", Min = 4, Max = 30, Default = 12, Step = .5, Suffix = " studs" });

        sl(SVA, { Name = "Radius", Flag = "SDAArcRadius", Min = 2, Max = 15, Default = 5, Step = .1, Suffix = " studs" });
        sl(SVA, { Name = "Duration", Flag = "SDAArcDuration", Min = .15, Max = 1, Default = .4, Step = .01, Suffix = "s" });
        sl(SVA, { Name = "Max Speed", Flag = "SDAMaxArcSpeed", Min = 40, Max = 250, Default = 120, Step = 1 });
        sl(SVA, { Name = "Dash Mult Cap", Flag = "SDADashMultCap", Min = .5, Max = 3, Default = 1.5, Step = .01 });
        sl(SVA, { Name = "Correction Speed", Flag = "SDACorrectionSpeed", Min = 50, Max = 300, Default = 150, Step = 1 });

        sl(SVU, { Name = "Curve Power", Flag = "SDACurvePow", Min = 1, Max = 8, Default = 3, Step = .1 });
        sl(SVU, { Name = "Curve Floor", Flag = "SDACurveFloor", Min = .01, Max = .5, Default = .08, Step = .01 });
    end;

    if bbk then
        local BBS = bfp:Section("Block Break");
        local BB = BBS:Group({ Name = "Block Break", Side = 1 });
        local BBT = BBS:Group({ Name = "Targeting", Side = 1 });
        local BBC = BBS:Group({ Name = "Arc", Side = 2 });
        local BBP = BBS:Group({ Name = "Positioning", Side = 2 });

        BB:Toggle({ Name = "Auto Block Break", Flag = "BBAuto", Default = false, Callback = function() bbk.sync(); end });
        BB:Toggle({ Name = "M1 Block Break", Flag = "BBM1", Default = false, Callback = function() bbk.sync(); end });
        BB:Toggle({ Name = "No Stick", Flag = "BBNoStick", Default = false });
        BB:Divider();
        BB:Button({ Name = "Block Break", Callback = function() bbk.fire(nil, true); end });
        BB:Keybind({ Name = "Break Key", Flag = "BBKey", Mode = "Hold", Callback = function(v)
            if v then bbk.fire(nil, true); end;
        end });

        BBT:Toggle({ Name = "Only Locked Target", Flag = "BBOnlyLocked", Default = false });
        BBT:Toggle({ Name = "Only Selected Target", Flag = "BBOnlySelected", Default = false });
        BBT:Toggle({ Name = "Lock While Dashing", Flag = "BBLock", Default = false });
        BBT:Toggle({ Name = "Punish After Dash", Flag = "BBPunish", Default = true });
        tgtdd(BBT, "BBTarget");

        BBC:Toggle({ Name = "Customize Arc", Flag = "BBCustomize", Default = false });
        BBC:Toggle({ Name = "Curve", Flag = "BBCurve", Default = false });
        BBC:Dropdown({ Name = "Curve Type", Flag = "BBCurveType", Values = { "Linear", "Ease-In", "Ease-Out", "Ease-In-Out" }, Default = "Ease-Out" });
        BBC:Toggle({ Name = "Cycle Curve", Flag = "BBCycleCurve", Default = false });
        BBC:Toggle({ Name = "Curve Affects Dash", Flag = "BBCurveDash", Default = false });

        BBP:Toggle({ Name = "Lock Arc Point", Flag = "BBLockArc", Default = false });
        BBP:Toggle({ Name = "Backflip", Flag = "BBBackflip", Default = false });
        BBP:Toggle({ Name = "Predict Back", Flag = "BBBackPred", Default = false });
        BBP:Toggle({ Name = "Arc Over Target", Flag = "BBArcOver", Default = false });

        local BBV = bfp:Section("Block Break Values");
        local BVC = BBV:Group({ Name = "Core", Side = 1 });
        local BVP = BBV:Group({ Name = "Positioning", Side = 1 });
        local BVA = BBV:Group({ Name = "Arc", Side = 2 });
        local BVU = BBV:Group({ Name = "Curve", Side = 2 });

        sl(BVC, { Name = "Range", Flag = "BBDist", Min = 5, Max = 60, Default = 30, Step = 1, Suffix = " studs" });
        sl(BVC, { Name = "Cooldown", Flag = "BBCd", Min = .5, Max = 3, Default = 1, Step = .01, Suffix = "s" });
        sl(BVC, { Name = "Auto Delay", Flag = "BBAutoDelay", Min = 0, Max = 1, Default = 0, Step = .01, Suffix = "s" });
        sl(BVC, { Name = "M1 Delay", Flag = "BBM1Delay", Min = 0, Max = 1, Default = 0, Step = .01, Suffix = "s" });
        sl(BVC, { Name = "Punish Timing", Flag = "BBPunishT", Min = .01, Max = 1, Default = .12, Step = .01, Suffix = "s" });

        sl(BVP, { Name = "Back Pred Strength", Flag = "BBBackPredStrength", Min = 0, Max = 2, Default = 1, Step = .01 });
        sl(BVP, { Name = "Arc Height", Flag = "BBArcHeight", Min = 4, Max = 30, Default = 12, Step = .5, Suffix = " studs" });

        sl(BVA, { Name = "Radius", Flag = "BBArcRadius", Min = 2, Max = 15, Default = 5, Step = .1, Suffix = " studs" });
        sl(BVA, { Name = "Duration", Flag = "BBArcDuration", Min = .15, Max = 1, Default = .4, Step = .01, Suffix = "s" });
        sl(BVA, { Name = "Max Speed", Flag = "BBMaxArcSpeed", Min = 40, Max = 250, Default = 120, Step = 1 });
        sl(BVA, { Name = "Dash Mult Cap", Flag = "BBDashMultCap", Min = .5, Max = 3, Default = 1.5, Step = .01 });
        sl(BVA, { Name = "Correction Speed", Flag = "BBCorrectionSpeed", Min = 50, Max = 300, Default = 150, Step = 1 });

        sl(BVU, { Name = "Curve Power", Flag = "BBCurvePow", Min = 1, Max = 8, Default = 3, Step = .1 });
        sl(BVU, { Name = "Curve Floor", Flag = "BBCurveFloor", Min = .01, Max = .5, Default = .08, Step = .01 });
    end;

    local ABMain = abp:Section("Main");
    local AL = ABMain:Group({ Name = "Block", Side = 1 });
    local AC = ABMain:Group({ Name = "Configuration", Side = 2 });

    local abt = AL:Toggle({ Name = "Enabled", Flag = "ABEnabled", Default = false, Callback = function(v) bk.toggle(v); end });
    abt:Keybind({ Flag = "ABKey", Mode = "Toggle" });
    AL:Toggle({ Name = "Only Locked Target", Flag = "ABOnlyLocked", Default = false });

    AL:Toggle({ Name = "Only Block Angle", Flag = "ABOnlyAngle", Default = false });
    AL:Toggle({ Name = "Show Angle", Flag = "ABAngleVis", Default = false, Callback = function(v) bk.vis(v); end });
    AL:Toggle({ Name = "Only Block Selected Target", Flag = "ABOnlySelected", Default = false });
    tgtdd(AL, "ABTarget");

    sl(AC, { Name = "Block Range", Flag = "ABRange", Min = 5, Max = 150, Default = 20, Step = 1, Suffix = " studs", Callback = function() bk.visgeo(); end });
    sl(AC, { Name = "Block Angle", Flag = "ABAngle", Min = 10, Max = 360, Default = 90, Step = 5, Suffix = "°", Callback = function() bk.visgeo(); end });

    local ABPun = abp:Section("Punish");
    local PU = ABPun:Group({ Name = "Punish", Side = 1 });
    local PC = ABPun:Group({ Name = "Configuration", Side = 2 });

    PU:Toggle({ Name = "Auto Punish", Flag = "ABPunish", Default = true, Callback = function(v)
        if v then bk.start(); end;
    end });
    PU:Toggle({ Name = "Hold Block Til M1", Flag = "ABHoldM1", Default = false });
    PU:Toggle({ Name = "Punish After Side Dash", Flag = "ABDashPunish", Default = false, Callback = function(v)
        if v then bk.start(); end;
    end });
    PU:Toggle({ Name = "M1 Catch", Flag = "M1Catch", Default = false, Callback = function(v)
        if v then bk.start(); end;
    end });

    sl(PC, { Name = "Punish Range", Flag = "ABPunishRange", Min = 5, Max = 80, Default = 25, Step = 1, Suffix = " studs" });
    sl(PC, { Name = "Hits To Release", Flag = "ABHitCount", Min = 1, Max = 6, Default = 1, Step = 1 });
    sl(PC, { Name = "Hold Timeout", Flag = "ABHoldTimeout", Min = .2, Max = 6, Default = 2, Step = .1, Suffix = "s" });
    sl(PC, { Name = "Dash Punish Delay", Flag = "ABDashPunishT", Min = 0, Max = .5, Default = .05, Step = .01, Suffix = "s" });
    sl(PC, { Name = "M1 Catch Range", Flag = "M1CatchRange", Min = 5, Max = 100, Default = 30, Step = 1, Suffix = " studs" });

    local ABCtr = abp:Section("Counter");
    local CT = ABCtr:Group({ Name = "Counter", Side = 1 });
    local CC = ABCtr:Group({ Name = "Configuration", Side = 2 });

    local ctt = CT:Toggle({ Name = "Auto Counter", Flag = "AutoCounter", Default = false, Callback = function(v)
        if v then bk.start(); end;
    end });
    ctt:Keybind({ Flag = "CTKey", Mode = "Toggle" });
    CT:Toggle({ Name = "Only If Facing Me", Flag = "CTFront", Default = false });

    sl(CC, { Name = "Counter Range", Flag = "CTRange", Min = 5, Max = 100, Default = 25, Step = 1, Suffix = " studs" });

    local PL = prp:Group({ Name = "Tracking", Side = 1 });
    local PR = prp:Group({ Name = "Lock On", Side = 2 });

    sl(PL, { Name = "Predict Strength", Flag = "PredictStrength", Min = 0, Max = 3, Default = 1, Step = .01 });
    PL:Toggle({ Name = "Smoothing Comp", Flag = "PredSmoothComp", Default = false });
    sl(PL, { Name = "Smoothing Comp Mul", Flag = "PredSmoothCompMul", Min = 0, Max = 1, Default = .15, Step = .01 });

    local lockt = PR:Toggle({ Name = "Lock On", Flag = "LockOn", Default = false, Callback = function(v)
        if v then lk.start(bf.target or lk.aim() or bf.autotgt()); else lk.arm(); end;
    end });
    lockt:Keybind({ Flag = "LockKey", Mode = "Toggle" });
    local lockb = PR:Toggle({ Name = "Lock On While Blocking", Flag = "LockBlock", Default = false, Callback = function(v)
        if v and bk then bk.start(); end;
        lk.arm();
    end });
    lockb:Keybind({ Flag = "LockBlockKey", Mode = "Toggle" });
    PR:Dropdown({ Name = "Block Lock Target", Flag = "LockBlockMode", Values = { "Closest", "Selected" }, Default = "Closest" });
    tgtdd(PR, "LockBlockTarget");
    PR:Toggle({ Name = "Auto Lock On BFC", Flag = "BFCAutoLock", Default = true });
    PR:Dropdown({ Name = "Target Mode", Flag = "LockTargetMode", Values = { "Closest", "Crosshair" },
        Default = (sv.uis.TouchEnabled and not sv.uis.KeyboardEnabled) and "Crosshair" or "Closest" });
    sl(PR, { Name = "Target Range", Flag = "LockRange", Min = 20, Max = 500, Default = 200, Step = 10, Suffix = " studs" });
    PR:Dropdown({ Name = "Method", Flag = "LockMethod", Values = { "Character", "Camera", "Both" }, Default = "Character", Callback = function(v)
        if v == "Character" then lk.relcam(); end;
    end });
    sl(PR, { Name = "Lock Smoothing", Flag = "LockSmoothing", Min = 0, Max = 1, Default = 0, Step = .01 });
    sl(PR, { Name = "Cam Side", Flag = "LockCamX", Min = -15, Max = 15, Default = 0, Step = .5, Suffix = " studs" });
    sl(PR, { Name = "Cam Height", Flag = "LockCamY", Min = -15, Max = 15, Default = 0, Step = .5, Suffix = " studs" });
    sl(PR, { Name = "Cam Distance", Flag = "LockCamZ", Min = -15, Max = 15, Default = 0, Step = .5, Suffix = " studs" });

    local CBAuto = cbp:Section("Auto's");
    local CA = CBAuto:Group({ Name = "Reactive TP", Side = 1 });
    CA:Toggle({ Name = "TP When Looking At You", Flag = "TPLook", Default = false, Callback = function(v) ms.tplook(v); end });
    CA:Toggle({ Name = "TP Behind", Flag = "TPLookBehind", Default = true });
    sl(CA, { Name = "Look Angle", Flag = "TPLookAngle", Min = 10, Max = 90, Default = 45, Step = 1, Suffix = "°" });
    sl(CA, { Name = "Stand Off", Flag = "TPLookDist", Min = 1, Max = 10, Default = 3, Step = .1, Suffix = " studs" });
    sl(CA, { Name = "Cooldown", Flag = "TPLookCD", Min = .1, Max = 3, Default = .5, Step = .05, Suffix = "s" });

    if caps.ok("LastM1") then
        local CM = CBAuto:Group({ Name = "Always Last M1", Side = 2 });
        CM:Dropdown({ Name = "Force M1 Into", Flag = "LastM1", Values = { "Off", "Uppercut", "Downslam" }, Default = "Off", Callback = function(v)
            ms.lastm1(v == "Uppercut" and "Up" or v == "Downslam" and "Down" or nil);
        end });
    end;

    if ms.abilok and ms.abilok() then
        local CAH = CBAuto:Group({ Name = "Ability Hook", Side = 1 });
        CAH:Toggle({ Name = "Auto Aim Abilities", Flag = "AbilAim", Default = false, Callback = function(v) ms.abilaim(v); end });
        sl(CAH, { Name = "Aim Range", Flag = "AbilAimRange", Min = 10, Max = 300, Default = 100, Step = 5, Suffix = " studs" });
        CAH:Toggle({ Name = "Auto Deactivate", Flag = "AbilDeac", Default = false, Callback = function(v) ms.abildeac(v); end });
        sl(CAH, { Name = "Deactivate Delay", Flag = "AbilDeacDelay", Min = .1, Max = 3, Default = .5, Step = .05, Suffix = "s" });
    end;

    local CVD = CBAuto:Group({ Name = "Void", Side = 2 });
    sl(CVD, { Name = "Void Height", Flag = "RespVoid", Min = -20000, Max = 20000, Default = 10000, Step = 1000, Suffix = " studs" });

    local CBChar = cbp:Section("Character Auto's");
    local CN = CBChar:Group({ Name = "Nanami", Side = 1 });
    CN:Toggle({ Name = "Auto Ratio", Flag = "AutoRatio", Default = false, Callback = function(v) ms.autoratio(v); end });
    sl(CN, { Name = "Timing", Flag = "RatioTiming", Min = .3, Max = 1, Default = .7, Step = .05 });

    local CHK = CBChar:Group({ Name = "Hakari", Side = 2 });
    CHK:Toggle({ Name = "Auto 4th", Flag = "AutoHK4", Default = false, Callback = function(v) ms.autofollow(v); end });
    CHK:Toggle({ Name = "Auto Ball", Flag = "AutoHKB", Default = false, Callback = function(v) ms.autofollow(v); end });

    local CGJ = CBChar:Group({ Name = "Gojo", Side = 1 });
    CGJ:Toggle({ Name = "Auto 3+R", Flag = "AutoGojo3R", Default = false, Callback = function(v) ms.autofollow(v); end });
    CGJ:Toggle({ Name = "Auto 4+R", Flag = "AutoGojo4R", Default = false, Callback = function(v) ms.autofollow(v); end });
    sl(CGJ, { Name = "Air Height", Flag = "GojoAirMin", Min = 3, Max = 20, Default = 7, Step = .5, Suffix = " studs" });
    sl(CGJ, { Name = "Window", Flag = "GojoAirBand", Min = 1, Max = 10, Default = 3, Step = .5, Suffix = " studs" });

    local CMG = CBChar:Group({ Name = "Megumi", Side = 2 });
    CMG:Toggle({ Name = "Auto Toad + Nue", Flag = "AutoMegToad", Default = false, Callback = function(v) ms.autofollow(v); end });
    CMG:Toggle({ Name = "Auto Bird Fly", Flag = "AutoMegBird", Default = false, Callback = function(v) ms.autofollow(v); end });
    CMG:Toggle({ Name = "Auto Shadow + Rabbit", Flag = "AutoMegRabbit", Default = false, Callback = function(v) ms.autofollow(v); end });
    sl(CMG, { Name = "Rabbit Range", Flag = "MegRabbitRange", Min = 3, Max = 40, Default = 10, Step = .5, Suffix = " studs" });

    local CHG = CBChar:Group({ Name = "Higurama", Side = 1 });
    CHG:Toggle({ Name = "Auto 4 + 1", Flag = "AutoHig4", Default = false, Callback = function(v) ms.autofollow(v); end });
    sl(CHG, { Name = "4 + 1 Delay", Flag = "AutoHig4Delay", Min = 0, Max = 3, Default = .8, Step = .05, Suffix = "s" });
    CHG:Toggle({ Name = "Auto 4 + 2", Flag = "AutoHig42", Default = false, Callback = function(v) ms.autofollow(v); end });
    sl(CHG, { Name = "4 + 2 Delay", Flag = "AutoHig42Delay", Min = 0, Max = 3, Default = .8, Step = .05, Suffix = "s" });
    if vo then
        CHG:Toggle({ Name = "Vote Viewer", Flag = "VoteView", Default = false, Callback = function(v) vo.set(v); end }):Keybind({ Flag = "VoteViewKey", Mode = "Toggle" });
    end;
    CHG:Toggle({ Name = "Auto QTE", Flag = "AutoHiguQTE", Default = false, Callback = function(v) ms.higu(v); end });
    CHG:Toggle({ Name = "Auto Domain", Flag = "AutoHiguDomain", Default = false, Callback = function(v) ms.higu(v); end });
    CHG:Dropdown({ Name = "Domain Choice", Flag = "HiguChoice", Values = { "Silence", "Confess", "Denial", "Random" }, Default = "Silence" });
    sl(CHG, { Name = "Miss Chance", Flag = "HiguMiss", Min = 0, Max = 100, Default = 0, Step = 1, Suffix = "%" });
    sl(CHG, { Name = "Delay", Flag = "HiguDelay", Min = 0, Max = 1, Default = 0, Step = .05, Suffix = "s" });

    local CHR = CBChar:Group({ Name = "Haruta", Side = 2 });
    CHR:Toggle({ Name = "Auto Dodge", Flag = "HarutaDodge", Default = false, Callback = function(v)
        if v and bk then bk.start(); end;
    end });
    sl(CHR, { Name = "Dodge Range", Flag = "HarutaDodgeDist", Min = 5, Max = 60, Default = 20, Step = 1, Suffix = " studs" });
    sl(CHR, { Name = "Dodge Hold", Flag = "HarutaDodgeHold", Min = .1, Max = 2, Default = .4, Step = .05, Suffix = "s" });
    CHR:Toggle({ Name = "Auto Backstab", Flag = "AutoBackstab", Default = false, Callback = function(v) ms.autofollow(v); end });

    local CRY = CBChar:Group({ Name = "Ryu", Side = 2 });
    CRY:Toggle({ Name = "Auto Dash + 1", Flag = "AutoRyuDash1", Default = false, Callback = function(v) ms.autofollow(v); end });

    local CYK = CBChar:Group({ Name = "Yuki", Side = 2 });
    CYK:Toggle({ Name = "Auto Garuda Rebound", Flag = "AutoYGR2", Default = false, Callback = function(v) ms.autofollow(v); end });
    CYK:Toggle({ Name = "Auto Garuda Rebound R", Flag = "AutoYGR", Default = false, Callback = function(v) ms.autofollow(v); end });
    CYK:Toggle({ Name = "Auto Rising Star R", Flag = "AutoYRR", Default = false, Callback = function(v) ms.autofollow(v); end });
    CYK:Toggle({ Name = "Auto Mass Breaker R", Flag = "AutoYMB", Default = false, Callback = function(v) ms.autofollow(v); end });
    CYK:Toggle({ Name = "Auto Garuda Stab R", Flag = "AutoYGS", Default = false, Callback = function(v) ms.autofollow(v); end });

    local CTD = CBChar:Group({ Name = "Todo", Side = 1 });
    CTD:Toggle({ Name = "Auto Perfect Clap", Flag = "AutoTodoClap", Default = false, Callback = function(v) ms.todo(v); end });
    CTD:Toggle({ Name = "Auto R Variant", Flag = "AutoTodoR", Default = false, Callback = function(v) ms.autofollow(v); end });
    CTD:Toggle({ Name = "Auto R Hit", Flag = "AutoRHit", Default = false, Callback = function(v) ms.todorhit(v); end });
    CTD:Toggle({ Name = "Dash After Swap", Flag = "TodoM1Swap", Default = false, Callback = function(v) ms.todo(v); end });
    sl(CTD, { Name = "M1 Delay", Flag = "TodoM1SwapDelay", Min = 0, Max = 600, Default = 70, Step = 5, Suffix = "ms" });
    CTD:Divider();
    CTD:Button({ Name = "Swap 2 Nearest", Callback = function() ms.todoswap2(); end });
    CTD:Keybind({ Name = "Swap Key", Flag = "TodoSwapKey", Mode = "Hold", Callback = function(v)
        if v then ms.todoswap2(); end;
    end });
    sl(CTD, { Name = "Swap Range", Flag = "TodoSwapDist", Min = 10, Max = 150, Default = 60, Step = 1, Suffix = " studs" });
    sl(CTD, { Name = "Swap Cooldown", Flag = "TodoSwapCD", Min = .05, Max = 2, Default = .2, Step = .05, Suffix = "s" });

    local CBC = cbp:Section("Combat");
    local CH = CBC:Group({ Name = "Hitbox", Side = 2 });
    CH:Toggle({ Name = "Hitbox Expander", Flag = "Hitbox", Default = false, Callback = function(v) ms.hitbox(v); end });
    sl(CH, { Name = "Hitbox Size", Flag = "HitboxSize", Min = 5, Max = 45, Default = 20, Step = .5, Callback = function(v) ms.hitboxsize(v); end });

    local CO = CBC:Group({ Name = "Orbit", Side = 1 });
    local orbt = CO:Toggle({ Name = "Orbit Target", Flag = "OrbitEnabled", Default = false, Callback = function(v) ms.orbit(v); end });
    orbt:Keybind({ Flag = "OrbitKey", Mode = "Hold" });
    CO:Dropdown({ Name = "Target", Flag = "OrbitMode", Values = { "Mouse", "Nearest" }, Default = "Mouse" });
    sl(CO, { Name = "Range", Flag = "OrbitRange", Min = 3, Max = 30, Default = 8, Step = .1, Suffix = " studs" });
    sl(CO, { Name = "Speed", Flag = "OrbitSpeed", Min = 30, Max = 720, Default = 180, Step = 5, Suffix = "°/s" });

    local MSMove = msp:Section("Movement");
    local MM = MSMove:Group({ Name = "Movement", Side = 1 });
    MM:Toggle({ Name = "Infinite Jump", Flag = "InfJump", Default = false, Callback = function(v) ms.infjump(v); end });
    if caps.ok("InfDash") then
        MM:Toggle({ Name = "Infinite Dash", Flag = "InfDash", Default = false, Callback = function(v) ms.infdash(v); end });
    end;
    MM:Toggle({ Name = "Auto Roll", Flag = "AutoRoll", Default = false, Callback = function(v) ms.autoroll(v); end });
    local wst = MM:Toggle({ Name = "Walkspeed", Flag = "WSOn", Default = false, Callback = function(v) ms.ws(v); end });
    wst:Keybind({ Flag = "WSKey", Mode = "Toggle" });
    sl(MM, { Name = "Speed", Flag = "WSVal", Min = 8, Max = 200, Default = 16, Step = 1 });
    MM:Toggle({ Name = "Anti Stun", Flag = "AntiStun", Default = false, Callback = function(v) ms.antistun(v); end });
    MM:Toggle({ Name = "No Block Slow", Flag = "NoBlockSlow", Default = false, Callback = function(v) ms.noblockslow(v); end });
    sl(MM, { Name = "Block Speed", Flag = "BlockSpeed", Min = 6, Max = 40, Default = 16, Step = 1, Suffix = " ws" });
    MM:Toggle({ Name = "Walk Into Domains", Flag = "DomWalk", Default = false, Callback = function(v) ms.domwalk(v); end });

    if fy then
        local MFL = MSMove:Group({ Name = "Fly", Side = 1 });
        local flt;
        flt = MFL:Toggle({ Name = "Fly", Flag = "FlyOn", Default = false, Callback = function(v)
            if fy.set(v) == false then
                flt:Set(false, true);
                note("Fly", "no character", "wind");
            end;
        end });
        flt:Keybind({ Flag = "FlyKey", Mode = "Toggle" });
        sl(MFL, { Name = "Speed", Flag = "FlySpeed", Min = 20, Max = 400, Default = 180, Step = 5 });
        sl(MFL, { Name = "Boost Speed", Flag = "FlyBoost", Min = 50, Max = 800, Default = 400, Step = 10 });
        sl(MFL, { Name = "Slow Speed", Flag = "FlySlow", Min = 5, Max = 200, Default = 80, Step = 5 });
        sl(MFL, { Name = "FOV Kick", Flag = "FlyFov", Min = 0, Max = 60, Default = 35, Step = 1 });
        MFL:Keybind({ Name = "Boost", Flag = "FlyBoostKey", Mode = "Hold", Callback = function(v) fy.boost(v); end });
        MFL:Keybind({ Name = "Slow", Flag = "FlySlowKey", Mode = "Hold", Callback = function(v) fy.slow(v); end });
    end;

    if pkr then
        local MPK = MSMove:Group({ Name = "Parkour", Side = 2 });
        if pkr.ok then
            local pkt = MPK:Toggle({ Name = "Auto Parkour", Flag = "PkOn", Default = false, Callback = function(v) pkr.set(v); end });
            pkt:Keybind({ Flag = "PkKey", Mode = "Toggle" });
            MPK:Toggle({ Name = "Vault, Dive and Slide", Flag = "PkGround", Default = true });
            MPK:Toggle({ Name = "Wall Jumps", Flag = "PkWall", Default = true });
            MPK:Toggle({ Name = "Start From Ground", Flag = "PkStart", Default = true });
            MPK:Toggle({ Name = "Hold Sprint", Flag = "PkSprint", Default = true });
            local pki = MPK:Toggle({ Name = "Unlimited Wall Jumps", Flag = "PkInfinite", Default = false, Callback = function(v) pkr.setinf(v); end });
            pki:Keybind({ Flag = "PkInfKey", Mode = "Toggle" });
            sl(MPK, { Name = "Wall Jump Gap", Flag = "PkWallGap", Min = .1, Max = 1, Default = .3, Step = .05, Suffix = "s" });
            sl(MPK, { Name = "Check Rate", Flag = "PkRate", Min = 5, Max = 60, Default = 20, Step = 5, Suffix = " hz" });
        else
            MPK:Label("Movement controller not reachable");
        end;
    end;

    local MSF = MSMove:Group({ Name = "Surf Tech", Side = 2 });
    MSF:Toggle({ Name = "Auto Surf Tech", Flag = "AutoSurf", Default = false, Callback = function(v) ms.surf(v); end });
    sl(MSF, { Name = "Surf Range", Flag = "SurfRange", Min = 1, Max = 50, Default = 5, Step = 1, Suffix = " studs" });
    sl(MSF, { Name = "Head Stick Time", Flag = "SurfStick", Min = 0, Max = 1, Default = .3, Step = .05, Suffix = "s" });

    local MHT = MSMove:Group({ Name = "Head Tap", Side = 2 });
    MHT:Toggle({ Name = "Auto Head Tap", Flag = "AutoHeadTap", Default = false, Callback = function(v) ms.headtap(v); end });
    sl(MHT, { Name = "Head Tap Range", Flag = "HTRange", Min = 1, Max = 50, Default = 6, Step = .5, Suffix = " studs" });
    sl(MHT, { Name = "Head Stick Time", Flag = "HTStick", Min = .1, Max = 2, Default = .6, Step = .05, Suffix = "s" });
    sl(MHT, { Name = "Tap Rate", Flag = "HTRate", Min = .025, Max = .5, Default = .05, Step = .005, Suffix = "s" });

    local MSUtil = msp:Section("Utility");
    local MU = MSUtil:Group({ Name = "Player", Side = 1 });
    MU:Toggle({ Name = "Extra Emote Slot", Flag = "EmoteSlot", Default = false, Callback = function(v) ms.emoteslot(v); end });
    local invt;
    invt = MU:Toggle({ Name = "Invisibility", Flag = "Invis", Default = false, Callback = function(v)
        if not iv then return; end;
        if iv.set(v) == false then
            invt:Set(false, true);
            note("Invisibility", "no character to hide", "eye-off");
        end;
    end });
    invt:Keybind({ Flag = "InvisKey", Mode = "Toggle" });

    if avm then
        local MA = MSUtil:Group({ Name = "Avatar", Side = 1 });
        local abusy = false;
        local function run(f, tag, arg)
            if abusy then return; end;
            abusy = true;
            task.spawn(function()
                local ok, why = f(arg);
                abusy = false;
                note("Avatar", ok and (tag .. " " .. tostring(why)) or ("failed: " .. tostring(why)), "shirt");
            end);
        end;
        MA:Button({ Name = "Scramble Avatar", Callback = function() run(avm.rand, "scrambled"); end });
        MA:Button({ Name = "Copy Random Player", Callback = function() run(avm.randplayer, "copied"); end });
        MA:Divider();
        MA:Input({ Name = "Target", Flag = "AvTarget", Holder = "username or id" });
        MA:Button({ Name = "Copy Avatar", Callback = function()
            local t = lib.flags.AvTarget;
            if not t or t == "" then return note("Avatar", "enter a username or id", "shirt"); end;
            run(avm.copy, "copied", t);
        end });
        MA:Button({ Name = "Restore Avatar", Callback = function() run(avm.restore, "restored"); end });
    end;

    if rsp then
        local MRS = MSUtil:Group({ Name = "Respawn", Side = 1 });
        if rsp.ok then
            local rst = MRS:Toggle({ Name = "Instant Respawn", Flag = "RespOn", Default = false, Callback = function(v) rsp.set(v); end });
            rst:Keybind({ Flag = "RespKey", Mode = "Toggle" });
            MRS:Toggle({ Name = "Force Death Register", Flag = "RespBreak", Default = true });
            sl(MRS, { Name = "Delay", Flag = "RespDelay", Min = 0, Max = 2, Default = 0, Step = .05, Suffix = "s" });
            sl(MRS, { Name = "Desync Hold", Flag = "RespHold", Min = .1, Max = 2, Default = .5, Step = .05, Suffix = "s" });
            MRS:Button({ Name = "Respawn Now", Callback = function()
                if not rsp.now() then note("Respawn", "no character", "rotate-ccw"); end;
            end });
        else
            MRS:Label("Reset remote not found");
        end;
    end;

    local MI = MSUtil:Group({ Name = "Item Grabber", Side = 2 });
    local itmdd = MI:Dropdown({ Name = "Item", Flag = "GrabItem", Values = ms.items(), Default = "None", Search = true });
    MI:Button({ Name = "Refresh", Callback = function() itmdd:SetValues(ms.items(), true); end });
    MI:Button({ Name = "Grab", Callback = function()
        if not ms.grab(lib.flags.GrabItem) then note("Item Grabber", "not found", "box"); end;
    end });

    local MT = msp:Section("Teleport"):Group({ Name = "Teleport Attack", Side = 1 });
    local tpat = MT:Toggle({ Name = "Teleport Attack", Flag = "TPAttack", Default = false, Callback = function(v) ms.tpattack(v); end });
    tpat:Keybind({ Flag = "TPAKey", Mode = "Toggle" });
    sl(MT, { Name = "Max Range", Flag = "TPARange", Min = 10, Max = 250, Default = 100, Step = 1, Suffix = " studs" });
    sl(MT, { Name = "Stand Off", Flag = "TPADist", Min = 1, Max = 10, Default = 3, Step = .1, Suffix = " studs" });
    sl(MT, { Name = "Lead", Flag = "TPALead", Min = 0, Max = .25, Default = .06, Step = .01, Suffix = "s" });
    sl(MT, { Name = "Hold", Flag = "TPAHold", Min = .1, Max = 1, Default = .2, Step = .05, Suffix = "s" });
    MT:Toggle({ Name = "Return After", Flag = "TPAReturn", Default = true });

    if byp and byp.ok then
        local BG = msp:Section("Anti-Cheat"):Group({ Name = "AC Bypass", Side = 1 });
        BG:Button({ Name = "Start Bypass", Callback = function()
            if byp.st.busy then return note("Bypass", "already running", "shield"); end;
            byp.start();
            note("Bypass", "started", "shield");
        end });
        BG:Button({ Name = "Cancel Bypass", Callback = function()
            if not byp.st.busy then return; end;
            byp.stop();
            note("Bypass", "cancelled", "shield-off");
        end });
        byp.onfinish = function()
            note("Bypass", "complete", "shield-check");
        end;
    end;

    if ar then
        local AUS = aup:Section("Aura");
        local gdef = { Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 0), Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 0, 255) };
        local hooks = {
            { "Effects", "Efx", 1, ar.efx, Color3.fromRGB(255, 0, 255) },
            { "Character", "Aura", 2, ar.aura, Color3.fromRGB(0, 200, 255) },
        };
        for _, e in hooks do
            local nm, pfx, side, hk, def = e[1], e[2], e[3], e[4], e[5];
            local G = AUS:Group({ Name = nm, Side = side });
            G:Toggle({ Name = "Enabled", Flag = pfx .. "On", Default = false, Callback = function(v) hk.set(v); end });
            G:Colorpicker({ Name = "Colour", Flag = pfx .. "Color", Default = def, NoAlpha = true, Callback = function() hk.repaint(); end });
            G:Divider();
            G:Toggle({ Name = "Rainbow", Flag = pfx .. "Rainbow", Default = false, Callback = function() hk.repaint(); end });
            G:Toggle({ Name = "Gradient Cycle", Flag = pfx .. "Grad", Default = false, Callback = function() hk.repaint(); end });
            sl(G, { Name = "Cycle Speed", Flag = pfx .. "Speed", Min = .05, Max = 3, Default = .4, Step = .05, Suffix = "x" });
            G:Divider("gradient");
            for i = 1, 4 do
                G:Colorpicker({ Name = "Colour " .. i, Flag = pfx .. "G" .. i, Default = gdef[i], NoAlpha = true, Callback = function() hk.repaint(); end });
            end;
        end;

        if caps.ok("Sounds") then
            local MUS = aup:Section("Music");
            local snd = { { "Domain Music", "Mus", 1, ar.mus },
                { "Black Flash", "Bfs", 2, ar.bfs } };
            for _, e in snd do
                local nm, pfx, side, hk = e[1], e[2], e[3], e[4];
                local G = MUS:Group({ Name = nm, Side = side, Info = "drop audio in the sounds folder next to your configs" });
                G:Toggle({ Name = "Replace", Flag = pfx .. "On", Default = false, Callback = function() hk.start(); end });
                local dd = G:Dropdown({ Name = "File", Flag = pfx .. "File", Values = ar.sounds(), Default = "None", Search = true, Callback = function() hk.reload(); end });
                G:Button({ Name = "Refresh", Callback = function() dd:SetValues(ar.sounds(), true); end });
                sl(G, { Name = "Volume", Flag = pfx .. "Vol", Min = 0, Max = 2, Default = 1, Step = .05, Suffix = "x", Callback = function() hk.apply(); end });
                sl(G, { Name = "Start At", Flag = pfx .. "Start", Min = 0, Max = 180, Default = 0, Step = 1, Suffix = "s", Callback = function() hk.apply(); end });
                sl(G, { Name = "Play Length", Flag = pfx .. "Clip", Min = 0, Max = 60, Default = 0, Step = 1, Suffix = "s", Callback = function() hk.apply(); end });
            end;
        else
            aup:Section("Music"):Group({ Name = "Music", Side = 1 }):Label("Executor cannot load custom audio");
        end;
    end;

    local COMBOREF = table.concat({
        "commands",
        "checkchar <name>",
        "wait <seconds>",
        "waitforanimend",
        "waitforattackanim",
        "waithit <timeout>",
        "bfc [delay] [waitforanimend]",
        "loopstart",
        "loopuntil <cond> [then <cmd>]",
        "key <name> [hold]",
        "press <name> [hold]",
        "m1 / m2",
        "block / unblock",
        "lockclosest [dist]",
        "lockselected / unlock",
        "settarget <mode|name>",
        "stopif <cond>",
        "if <cond> then <cmd>",
        "",
        "keys",
        "1 2 3 4 r q f e space",
        "w a s d",
        "",
        "conditions",
        "inult dead needburst",
        "thirdparty hitanim",
        "ragdolled stunned",
        "blocking notblocking",
        "lowhp whiffed",
        "",
        "enemy conditions",
        "any condition suffixed with enemy",
        "inultenemy, blockingenemy, ...",
    }, "\n");

    local CS = cmb:Section({ Name = "Advanced", Full = true });
    local CE = CS:Group({ Name = "Combo", Side = 1, Info = COMBOREF });
    local ced;
    if type(CE.Editor) == "function" then
        ced = CE:Editor({
            Flag = "ComboScript",
            Height = 320,
            Holder = "lockclosest 30\nm1\nm1\nm1\nwaitforanimend\nbfc\nstopif ragdolled",
        });
    else
        CE:Label("PotentUI is out of date, push the editor build");
    end;

    
    
    
    if ced and ced.i then
        local tb, sc;
        for _, d in ced.i:GetDescendants() do
            if d:IsA("TextBox") and d.MultiLine and d.Parent:IsA("ScrollingFrame") then
                tb, sc = d, d.Parent;
                break;
            end;
        end;
        if tb then
            
            
            tb.AutomaticSize = Enum.AutomaticSize.None;
            local TS = game:GetService("TextService");
            local ftok = 0;
            local function fit()
                ftok += 1;
                local my = ftok;
                task.spawn(function()
                    task.wait(.05);
                    if my ~= ftok then return; end;
                    local w = tb.AbsoluteSize.X;
                    if w < 1 then return; end;
                    local ok, r = pcall(function()
                        local pm = Instance.new("GetTextBoundsParams");
                        pm.Text = tb.Text ~= "" and tb.Text or " ";
                        pm.Font = tb.FontFace;
                        pm.Size = tb.TextSize;
                        pm.Width = w;
                        return TS:GetTextBoundsAsync(pm);
                    end);
                    if not (ok and my == ftok and tb.Parent) then return; end;
                    tb.Size = UDim2.new(1, 0, 0, math.max(math.ceil(r.Y) + 6, sc.AbsoluteSize.Y));
                end);
            end;
            ut.add(tb:GetPropertyChangedSignal("Text"):Connect(fit));
            ut.add(sc:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit));
            fit();
        end;
    end;

    if co then
        local function script()
            return (ced and ced:Get()) or lib.flags.ComboScript or "";
        end;
        CE:Button({ Name = "Play Now", Callback = function()
            if not co.play(script()) then note("Auto Combo", "nothing to play", "code"); end;
        end });
        CE:Button({ Name = "Stop", Callback = function() co.stop(); end });
        CE:Keybind({ Name = "Play On Keybind", Flag = "ComboKey", Mode = "Hold", Callback = function(v)
            if v then co.play(script()); end;
        end });

        local SIM = cmb:Section("Simple");
        local RG = SIM:Group({ Name = "Recorder", Side = 1 });
        local rlbl = RG:Label("Recorded: 0");
        local rt = RG:Toggle({ Name = "Record", Flag = "ComboRec", Default = false, Callback = function(v)
            local n = co.record(v);
            rlbl:Set(v and "Recording..." or ("Recorded: " .. n .. " actions"));
        end });
        rt:Keybind({ Flag = "ComboRecKey", Mode = "Toggle" });
        RG:Divider();
        RG:Button({ Name = "Play Recording", Callback = function()
            if not co.play(co.toscript()) then note("Auto Combo", "nothing recorded", "code"); end;
        end });
        RG:Button({ Name = "Send To Advanced", Callback = function()
            local t = co.toscript();
            if t == "" then note("Auto Combo", "nothing recorded", "code"); return; end;
            if ced then ced:Set(t); end;
            note("Auto Combo", co.count() .. " actions written", "code");
        end });

        if type(co.presets) == "table" and #co.presets > 0 then
            local PS = cmb:Section("Presets");
            local PG = PS:Group({ Name = "Presets", Side = 1 });
            for i, pr in co.presets do
                if i > 1 then PG:Divider(); end;
                PG:Button({ Name = pr.name, Callback = function()
                    if not co.playpreset(pr.name) then note("Auto Combo", "preset failed", "code"); end;
                end });
                PG:Keybind({ Name = pr.name, Flag = "ComboPreset" .. (pr.flag or i), Mode = "Hold", Callback = function(v)
                    if v then co.playpreset(pr.name); end;
                end });
                PG:Button({ Name = pr.name .. " To Editor", Callback = function()
                    if ced then ced:Set(pr.text); end;
                    note("Auto Combo", "loaded " .. pr.name, "code");
                end });
            end;
            PG:Divider();
            PG:Button({ Name = "Stop Preset", Callback = function() co.stop(); end });

            local PP = PS:Group({ Name = "Positioning", Side = 2 });
            PP:Toggle({ Name = "Stay Close To Player", Flag = "ComboStick", Default = false });
            sl(PP, { Name = "Distance", Flag = "ComboStickDist", Min = 2, Max = 20, Default = 4, Step = .5, Suffix = " studs" });
            sl(PP, { Name = "Smoothing", Flag = "ComboStickSmooth", Min = 5, Max = 100, Default = 25, Step = 5, Suffix = "%" });
        end;

        local SV = cmb:Section("Saved");
        local SG = SV:Group({ Name = "Manage", Side = 1 });
        SG:Input({ Name = "Name", Flag = "ComboName", Holder = "combo name" });
        local cdd;
        SG:Button({ Name = "Save", Callback = function()
            local ok, saved = co.save(lib.flags.ComboName, script());
            if not ok then note("Auto Combo", "save failed", "code"); return; end;
            cdd:SetValues(co.list(), true);
            cdd:Set(saved, true);
            note("Auto Combo", "saved " .. saved, "code");
        end });
        cdd = SG:Dropdown({ Name = "Saved", Flag = "ComboPick", Values = co.list(), Default = "None", Search = true });
        SG:Button({ Name = "Load", Callback = function()
            local t = co.load(lib.flags.ComboPick);
            if not t then note("Auto Combo", "not found", "code"); return; end;
            if ced then ced:Set(t); end;
        end });
        SG:Button({ Name = "Delete", Callback = function()
            if not co.del(lib.flags.ComboPick) then note("Auto Combo", "delete failed", "code"); return; end;
            cdd:SetValues(co.list(), true);
            cdd:Set("None", true);
        end });
        SG:Button({ Name = "Refresh", Callback = function() cdd:SetValues(co.list(), true); end });

        local SC = SV:Group({ Name = "Conditions", Side = 2 });
        sl(SC, { Name = "Low HP", Flag = "ComboLowHP", Min = 5, Max = 90, Default = 30, Step = 1, Suffix = "%" });
        sl(SC, { Name = "Third Party Range", Flag = "ComboThirdDist", Min = 10, Max = 150, Default = 40, Step = 1, Suffix = " studs" });
    end;

    local ep2 = ctx.esp;
    if ep2 then
        local ESEC = ep:Section("Players", "boxes, chams and text");
        local EG = ESEC:Group({ Name = "Main", Side = 1 });
        if not ep2.ok then
            EG:Label("Your executor has no drawing library");
            EG:Label("ESP needs DrawingImmediate or Drawing. Nothing here will do anything.");
        else
            local estat = EG:Label(ep2.mode == "immediate" and "Immediate mode" or "Retained mode");
            ut.add(sv.runs.Heartbeat:Connect(function()
                if not ep2.on then return; end;
                estat:Set(("%s | %d fps | quality %d | %d targets"):format(
                    ep2.mode == "immediate" and "Immediate" or "Retained",
                    ep2.fps or 0, 3 - (ep2.lvl or 0), (ep2.n or 0) + (ep2.items or 0)));
            end));
            EG:Toggle({ Name = "Enabled", Flag = "EspOn", Default = false, Callback = function() ep2.sync(); end }):Keybind({});
            sl(EG, { Name = "Max Distance", Flag = "EspDist", Min = 50, Max = 3000, Default = 1500, Step = 50, Suffix = " studs" });
            sl(EG, { Name = "Max Targets", Flag = "EspMax", Min = 1, Max = 30, Default = 12, Step = 1 });
            sl(EG, { Name = "Thickness", Flag = "EspThick", Min = 1, Max = 5, Default = 1, Step = 1, Suffix = " px" });
            sl(EG, { Name = "Text Size", Flag = "EspTextSize", Min = 8, Max = 26, Default = 14, Step = 1, Suffix = " px" });
            sl(EG, { Name = "Detail Cutoff", Flag = "EspLod", Min = 50, Max = 2000, Default = 250, Step = 25, Suffix = " studs" });
            EG:Toggle({ Name = "Auto Performance", Flag = "EspAuto", Default = true });
            EG:Divider();
            EG:Colorpicker({ Name = "Colour", Flag = "EspColor", Default = Color3.fromRGB(0, 255, 255), NoAlpha = true });
            EG:Colorpicker({ Name = "Outline", Flag = "EspOutColor", Default = Color3.fromRGB(0, 0, 0), NoAlpha = true });
            EG:Toggle({ Name = "Colour Locked Target", Flag = "EspLock", Default = false }):Colorpicker({ Flag = "EspLockColor", Default = Color3.fromRGB(255, 50, 50), NoAlpha = true });

            local EB = ESEC:Group({ Name = "Shapes", Side = 2 });
            EB:Toggle({ Name = "Corner Boxes", Flag = "EspCorner", Default = true });
            EB:Toggle({ Name = "Full Boxes", Flag = "EspBox", Default = false });
            EB:Toggle({ Name = "Outlines", Flag = "EspOutline", Default = true });
            EB:Toggle({ Name = "Head Dots", Flag = "EspHeadDot", Default = false });
            sl(EB, { Name = "Dot Size", Flag = "EspDotSize", Min = 2, Max = 12, Default = 4, Step = 1, Suffix = " px" });
            EB:Toggle({ Name = "Skeletons", Flag = "EspSkel", Default = false });
            EB:Colorpicker({ Name = "Skeleton Colour", Flag = "EspSkelColor", Default = Color3.fromRGB(255, 255, 255), NoAlpha = true });
            EB:Toggle({ Name = "Tracers", Flag = "EspTracer", Default = false });
            EB:Dropdown({ Name = "Tracer From", Flag = "EspTracerFrom", Values = { "Bottom", "Middle", "Top", "Mouse" }, Default = "Bottom" });

            local ETX = ep:Section("Text & Chams", "labels and highlights");
            local ET = ETX:Group({ Name = "Labels", Side = 1 });
            ET:Toggle({ Name = "Name", Flag = "EspNames", Default = true });
            ET:Dropdown({ Name = "Name Side", Flag = "EspNamePos", Values = { "Top", "Bottom", "Left", "Right" }, Default = "Top" });
            ET:Toggle({ Name = "Character", Flag = "EspChar", Default = false });
            ET:Dropdown({ Name = "Character Side", Flag = "EspCharPos", Values = { "Top", "Bottom", "Left", "Right" }, Default = "Top" });
            ET:Toggle({ Name = "Distance", Flag = "EspDistance", Default = false });
            ET:Dropdown({ Name = "Distance Side", Flag = "EspDistPos", Values = { "Top", "Bottom", "Left", "Right" }, Default = "Bottom" });
            ET:Toggle({ Name = "Kills", Flag = "EspKills", Default = false });
            ET:Dropdown({ Name = "Kills Side", Flag = "EspKillPos", Values = { "Top", "Bottom", "Left", "Right" }, Default = "Bottom" });
            ET:Divider();
            ET:Toggle({ Name = "Stun ESP", Flag = "EspStun", Default = false }):Keybind({});
            ET:Dropdown({ Name = "Stun Side", Flag = "EspStunPos", Values = { "Top", "Bottom", "Left", "Right" }, Default = "Top" });
            ET:Colorpicker({ Name = "Stun Colour", Flag = "EspStunColor", Default = Color3.fromRGB(255, 210, 60), NoAlpha = true });

            local EH = ETX:Group({ Name = "Health & Chams", Side = 2 });
            EH:Toggle({ Name = "Health Bar", Flag = "EspHealthBar", Default = false });
            EH:Dropdown({ Name = "Bar Side", Flag = "EspHealthSide", Values = { "Left", "Right" }, Default = "Left" });
            EH:Toggle({ Name = "Health Text", Flag = "EspHealthT", Default = false });
            EH:Dropdown({ Name = "Text Side", Flag = "EspHealthPos", Values = { "Right", "Left", "Top", "Bottom" }, Default = "Right" });
            EH:Colorpicker({ Name = "Health Colour", Flag = "EspHealthColor", Default = Color3.fromRGB(0, 255, 0), NoAlpha = true });
            EH:Divider();
            EH:Toggle({ Name = "Chams", Flag = "EspChams", Default = false });
            EH:Colorpicker({ Name = "Cham Fill", Flag = "EspChamsColor", Default = Color3.fromRGB(0, 255, 255), NoAlpha = true });
            EH:Colorpicker({ Name = "Cham Outline", Flag = "EspChamsOutColor", Default = Color3.fromRGB(255, 255, 255), NoAlpha = true });
            sl(EH, { Name = "Fill Transparency", Flag = "EspChamsFill", Min = 0, Max = 1, Default = .5, Step = .05 });
            sl(EH, { Name = "Outline Transparency", Flag = "EspChamsOut", Min = 0, Max = 1, Default = 0, Step = .05 });
            EH:Toggle({ Name = "Evasive Chams", Flag = "EspEvasive", Default = false });
            EH:Toggle({ Name = "Stun Chams", Flag = "EspStunChams", Default = false }):Keybind({});
            EH:Colorpicker({ Name = "Stun Cham Fill", Flag = "EspStunChamsColor", Default = Color3.fromRGB(255, 80, 80), NoAlpha = true });
            EH:Divider();
            EH:Toggle({ Name = "Cooldown Revealer", Flag = "EspReveal", Default = false, Callback = function(v) ep2.reveal(v); end });

            local ISEC = ep:Section("Items", "the items folder");
            local IG = ISEC:Group({ Name = "Item ESP", Side = 1 });
            IG:Toggle({ Name = "Enabled", Flag = "EspItemOn", Default = false, Callback = function() ep2.sync(); end }):Keybind({});
            sl(IG, { Name = "Max Distance", Flag = "EspItemDist", Min = 50, Max = 2000, Default = 500, Step = 25, Suffix = " studs" });
            IG:Colorpicker({ Name = "Colour", Flag = "EspItemColor", Default = Color3.fromRGB(255, 200, 60), NoAlpha = true });
            local IG2 = ISEC:Group({ Name = "Item Shapes", Side = 2 });
            IG2:Toggle({ Name = "Corner Boxes", Flag = "EspItemCorner", Default = true });
            IG2:Toggle({ Name = "Full Boxes", Flag = "EspItemBox", Default = false });
            IG2:Toggle({ Name = "Names", Flag = "EspItemNames", Default = true });
            IG2:Toggle({ Name = "Distance", Flag = "EspItemDistText", Default = false });
            IG2:Toggle({ Name = "Chams", Flag = "EspItemChams", Default = false });
        end;
    end;

    if pip then
        local pview = pip:Section({ Name = "Player", Desc = "We all know we aint learning piano", Full = true }):Group({ Bare = true });
        local roll;
        if type(pview.Piano) == "function" then
            roll = pview:Piano({ Fill = true, Height = 320, Look = 2.2, Clock = pia.elapsed });
            pia.roll = roll;
        else
            pview:Label("PotentUI is out of date, push the piano build");
        end;

        local pset = pip:Section("Settings", "song, speed and keys");
        local PS = pset:Group({ Name = "Song", Side = 1 });
        local plbl = PS:Label("Idle");

        local function draw()
            if roll then roll.on = pia.playing and not pia.paused; end;
        end;

        local pdd = PS:Dropdown({ Name = "File", Flag = "PianoFile", Values = pia.list(), Default = "None", Search = true, Holder = "none", Callback = function(v)
            if not v or v == "None" then return; end;
            local ok, r = pia.load(v);
            if not ok then
                plbl:Set("Idle");
                if roll then roll:Set({}); end;
                return note("Auto Piano", tostring(r), "music");
            end;
            if roll then
                roll:Set(r);
                roll:Stop();
            end;
            plbl:Set(("%d notes  |  %.1fs"):format(#r, pia.total));
        end });
        PS:Button({ Name = "Refresh", Callback = function()
            pdd:SetValues(pia.list(), true);
            note("Auto Piano", "drop .mid files in " .. pia.dir(), "music");
        end });
        PS:Button({ Name = "Open Folder Path", Callback = function()
            if setclipboard then setclipboard(pia.dir()); end;
            note("Auto Piano", "path copied, drop .mid files there", "music");
        end });
        PS:Divider();
        local purl = PS:Input({ Name = "Link", Flag = "PianoUrl", Holder = "direct .mid link", Center = false });
        local pnm = PS:Input({ Name = "Save As", Flag = "PianoUrlName", Holder = "optional name", Center = false });
        purl.nosave, pnm.nosave = true, true;
        PS:Button({ Name = "Download", Callback = function()
            local ok, r = pia.fetch(purl:Get(), pnm:Get());
            if not ok then return note("Auto Piano", tostring(r), "music"); end;
            pdd:SetValues(pia.list(), true);
            purl:Set("");
            note("Auto Piano", "saved " .. tostring(r), "music");
        end });

        local PP = pset:Group({ Name = "Playback", Side = 2 });
        sl(PP, { Name = "Speed", Flag = "PianoSpeed", Min = .25, Max = 4, Default = 1, Step = .05, Suffix = "x" });
        sl(PP, { Name = "Transpose", Flag = "PianoTrans", Min = -24, Max = 24, Default = 0, Step = 1, Suffix = " st" });
        PP:Toggle({ Name = "Visualise Only", Flag = "PianoMute", Default = false });
        PP:Divider();
        PP:Button({ Name = "Play", Callback = function()
            if not pia.notes then return note("Auto Piano", "load a song first", "music"); end;
            if pia.playing then
                pia.stop();
                if roll then roll:Stop(); end;
                task.wait();
            end;
            pia.play();
            if roll then roll:Play(); end;
        end });
        PP:Button({ Name = "Pause", Callback = function()
            pia.pause();
            draw();
        end });
        PP:Button({ Name = "Stop", Callback = function()
            pia.stop();
            if roll then roll:Stop(); end;
            plbl:Set(pia.notes and ("%d notes  |  %.1fs"):format(#pia.notes, pia.total) or "Idle");
        end });
        PP:Keybind({ Name = "Pause Key", Flag = "PianoPauseKey", Mode = "Hold", Callback = function(v)
            if not (v and pia.playing) then return; end;
            pia.pause();
            draw();
        end });
        PP:Keybind({ Name = "Play Key", Flag = "PianoKey", Mode = "Hold", Callback = function(v)
            if not (v and pia.notes) then return; end;
            if pia.playing then
                pia.stop();
                if roll then roll:Stop(); end;
                return;
            end;
            pia.play();
            if roll then roll:Play(); end;
        end });

        local pacc, plast = 0, "";
        ut.add(ctx.svc.runs.Heartbeat:Connect(function(dt)
            if not (lib.gui and pia.playing) then return; end;
            pacc += dt;
            if pacc < .25 then return; end;
            pacc = 0;
            local e, t = pia.elapsed(), pia.total;
            local txt = ("%d:%02d / %d:%02d%s"):format(e / 60, e % 60, t / 60, t % 60, pia.paused and "  (paused)" or "");
            if txt == plast then return; end;
            plast = txt;
            plbl:Set(txt);
        end));
    end;

    win:Category("Script");
    local set = win:Settings();
    local SS = set:Section("Script"):Group({ Name = "Script", Side = 1 });
    SS:Button({ Name = "Unload Script", Callback = function() task.defer(ctx.unload); end });
    SS:Keybind({ Name = "Unload Key", Flag = "UnloadKey", Mode = "Always", Callback = function()
        task.defer(ctx.unload);
    end });

    if type(lib.Wheel) == "function" then
        local WS = set:Section("Wheel"):Group({ Name = "Radial Wheel", Side = 1 });
        WS:Toggle({ Name = "Show Dot", Flag = "WheelDot", Default = true, Callback = function(v) lib:Bubble(v); end });
        WS:Toggle({ Name = "Wheel On Tap", Flag = "WheelTap", Default = true, Callback = function(v) lib:WheelMode(v); end });
        WS:Keybind({ Name = "Wheel Key", Flag = "WheelKey", Mode = "Always", Callback = function() lib:Wheel(); end });
        lib:Bubble(true);
    end;

    if lgc and caps.ok("Configs") then
        local ISEC = set:Section("Import");
        local IM = ISEC:Group({ Name = "Old Configs", Side = 1 });
        local ist = IM:Label("Found: 0");
        local idd = IM:Dropdown({ Name = "Config", Flag = "LegacyPick", Values = { "None" }, Default = "None", Search = true });
        idd.nosave = true;

        local function rescan()
            idd:SetValues(lgc.scan(), true);
            ist:Set("Found: " .. lgc.count());
        end;

        local function done(r, nm)
            local sv = nm ~= "" and nm or nil;
            if sv then
                lib:SaveCfg(sv);
                local cl = lib.opts.cfg_list;
                if cl then cl:SetValues(lib:Configs(), true); end;
            end;
            tiles[1]:Set(lib:Count());
            note("Import", r.applied .. " settings brought over, " .. r.dropped .. " had no match"
                .. (sv and (", saved as " .. sv) or ""), "folder-input");
        end;

        IM:Button({ Name = "Import", Callback = function()
            local n = lib.flags.LegacyPick;
            if not n or n == "None" then return note("Import", "pick a config first", "folder-input"); end;
            local r, why = lgc.import(lgc.path(n));
            if not r then return note("Import", tostring(why), "folder-input"); end;
            done(r, n .. " (old)");
        end });
        IM:Button({ Name = "Rescan", Callback = rescan });
        rescan();

        local IP = ISEC:Group({ Name = "Paste Config", Side = 2 });
        local ied;
        if type(IP.Editor) == "function" then
            ied = IP:Editor({ Flag = "LegacyText", Height = 220, Holder = '{"objects":[ ... ]}' });
        else
            ied = IP:Input({ Name = "Config", Flag = "LegacyText", Holder = "paste the json here", Center = false });
        end;
        local inm = IP:Input({ Name = "Save As", Flag = "LegacyName", Holder = "name", Center = false });
        ied.nosave, inm.nosave = true, true;
        IP:Button({ Name = "Import Pasted", Callback = function()
            local txt = ied:Get();
            local nm = lib.flags.LegacyName or "";
            local r, why = lgc.importtext(txt);
            if not r then return note("Import", tostring(why), "folder-input"); end;
            done(r, nm);
        end });
        IP:Button({ Name = "Clear", Callback = function() ied:Set(""); end });
    end;

    if mo then
        
        
        for _, e in btnreg do
            local nm = e.nm .. " [BUTTON]";
            if mo.acts[nm] then
                local base, i = nm .. " (" .. tostring(e.tab or "?") .. ")", 2;
                nm = base;
                while mo.acts[nm] do
                    nm = base .. " " .. i;
                    i += 1;
                end;
            end;
            local cb = e.cb;
            mo.acts[nm] = function() task.spawn(cb); end;
            mo.actcat[nm] = e.tab;
        end;

        
        
        
        
        
        
        
        for f, o in next, lib.opts do
            if type(o) == "table" and o.t == "keybind" and not o.owner and not o.inert
                and o.nm and o.nm ~= "bind" and o.cb then
                local nm = o.nm;
                if mo.acts[nm] then nm = nm .. " (" .. tostring(f) .. ")"; end;
                mo.actcat[nm] = mo.tab(f);
                local b = o;
                mo.acts[nm] = function()
                    if b.mode == "Toggle" then
                        b.on = not b.on;
                        task.spawn(b.cb, b.on);
                        return;
                    end;
                    task.spawn(b.cb, true);
                    if b.mode ~= "Hold" then return; end;
                    
                    b.on = true;
                    task.delay(tonumber(ctx.opt("MobileHoldT", .12)) or .12, function()
                        b.on = false;
                        task.spawn(b.cb, false);
                    end);
                end;
            end;
        end;
        local MB = msp:Section("Mobile"):Group({ Name = "On Screen Buttons", Side = 1 });
        MB:Toggle({ Name = "Mobile Buttons", Flag = "MobileBtns", Default = false, Callback = function(v) mo.on(v); end });
        MB:Toggle({ Name = "Lock Buttons", Flag = "MobileLock", Default = false, Callback = function(v) mo.setlock(v); end });
        local mbdd = MB:Dropdown({ Name = "Buttons", Flag = "MobileList", Values = mo.vals(), Group = mo.groups, MaxH = 300, Multi = true, Search = true, Holder = "none", Callback = function() mo.sync(); end });
        MB:Toggle({ Name = "Include Dropdowns", Flag = "MobileDrops", Default = true, Callback = function()
            mbdd:SetValues(mo.vals(), true);
            mo.sync();
        end });
        MB:Button({ Name = "Refresh List", Callback = function() mbdd:SetValues(mo.vals(), true); end });
        sl(MB, { Name = "Size", Flag = "MobileSize", Min = 30, Max = 200, Default = 60, Step = 1, Suffix = " px", Callback = function(v) mo.setsize(v); end });
        sl(MB, { Name = "Hold Pulse", Flag = "MobileHoldT", Min = .05, Max = 1, Default = .12, Step = .01, Suffix = "s" });
    end;

    lib.onunload = function() pcall(ctx.unload, true); end;

    local acc = 0;
    ut.add(ctx.svc.runs.Heartbeat:Connect(function(dt)
        acc += dt;
        if acc < .5 or not lib.gui then return; end;
        acc = 0;
        hp:Set(math.floor(tk.sping()) .. " ms");
        hf:Set(math.floor(tk.fps()));
        ha:Set(fl and #fl.allpaths or 0);
    end));

    tiles[1]:Set(lib:Count());

    if #caps.missing > 0 then
        task.delay(1, function()
            note("Unsupported executor", "Disabled: " .. table.concat(caps.missing, ", "));
        end);
    end;
    if caps.ok("Configs") then
        pcall(lib.LoadAuto, lib);
        if lgc and lgc.count() > 0 and #lib:Configs() == 0 then
            task.delay(2, function()
                note("Import", lgc.count() .. " old configs found, bring them over in Settings", "folder-input");
            end);
        end;
    end;
    local function buildaf()
        local th = lib.theme;
        local WARN = th.warn or Color3.fromRGB(224, 92, 92);
        local KINDS = af.kinds;
        local KCOL = {
            Block = th.act, Counter = th.acc, Punish = WARN,
            Multi = Color3.fromRGB(232, 184, 88),
            Adapt = Color3.fromRGB(96, 165, 250),
            Decisive = Color3.fromRGB(255, 122, 196),
        };
        local KPAR = {
            Block = { { "rng", "rng" }, { "hold", "hold" }, { "door", "dr" }, { "out", "dt" } },
            Counter = { { "rng", "rng" }, { "wait", "wait" }, { "at", "at" }, { "close", "cls" }, { "out", "out" } },
        };
        local HITCOL = Color3.fromRGB(255, 206, 84);

        local function nw(cls, props, par)
            local o = Instance.new(cls);
            for k, v in props do o[k] = v; end;
            o.Parent = par;
            return o;
        end;
        local function crn(o, r) nw("UICorner", { CornerRadius = UDim.new(0, r) }, o); end;
        local function tx(par, props)
            props.BackgroundTransparency = 1;
            props.Font = props.Font or Enum.Font.Gotham;
            props.TextSize = props.TextSize or 12;
            props.TextColor3 = props.TextColor3 or th.txt;
            props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left;
            return nw("TextLabel", props, par);
        end;

        local AFS = afp:Section("Editor");
        local AFF = afp:Section("Filter");
        local GL = AFS:Group({ Name = "Animations", Side = 1 });
        local GP = AFS:Group({ Name = "Preview", Side = 2 });
        local GF = AFS:Group({ Name = "Flags", Side = 2 });

        local cur, curlen, curtrk, curhits = nil, 1, nil, {};
        local playing, phead, spd, drag = false, 0, 1, false;
        local rebuild, drawflags, drawbars;

        local curset = "All";
        local mdd = GL:Dropdown({ Name = "Moveset", Values = af.sets(), Default = "All", Search = true, Callback = function(v)
            curset = v or "All";
            if rebuild then rebuild(); end;
        end });
        mdd.nosave = true;

        local sbw = nw("Frame", { Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 50, BackgroundColor3 = th.elem, BorderSizePixel = 0 }, GL.card);
        crn(sbw, 7);
        local sb = nw("TextBox", {
            Size = UDim2.new(1, -22, 1, 0), Position = UDim2.fromOffset(11, 0), BackgroundTransparency = 1,
            Text = "", PlaceholderText = "search", TextColor3 = th.txt, PlaceholderColor3 = th.dim,
            TextXAlignment = Enum.TextXAlignment.Left, TextSize = 12, Font = Enum.Font.Gotham, ClearTextOnFocus = false
        }, sbw);

        local lw = nw("Frame", { Size = UDim2.new(1, 0, 0, 226), LayoutOrder = 51, BackgroundColor3 = th.elem, BorderSizePixel = 0 }, GL.card);
        crn(lw, 8);
        local sf = nw("ScrollingFrame", {
            Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), BackgroundTransparency = 1,
            BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = th.dim,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y
        }, lw);
        nw("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, sf);

        local vpw = nw("Frame", { Size = UDim2.new(1, 0, 0, 236), BackgroundColor3 = th.bg, BorderSizePixel = 0 }, GP.card);
        crn(vpw, 9);
        local vp = nw("ViewportFrame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            Ambient = Color3.fromRGB(184, 184, 184), LightColor = Color3.fromRGB(255, 255, 255),
            LightDirection = Vector3.new(-.4, -1, -.25)
        }, vpw);
        local wm = nw("WorldModel", {}, vp);
        local cam = nw("Camera", {}, vp);
        vp.CurrentCamera = cam;

        local sel = tx(GP.card, { Size = UDim2.new(1, 0, 0, 16), Text = "no animation", TextColor3 = th.dim, TextSize = 12 });

        local ctl = nw("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, GP.card);
        local pb = nw("TextButton", {
            Size = UDim2.fromOffset(66, 28), Text = "Play", AutoButtonColor = false, BorderSizePixel = 0,
            BackgroundColor3 = th.elem, TextColor3 = th.txt, TextSize = 12, Font = Enum.Font.GothamMedium
        }, ctl);
        crn(pb, 7);
        local rsb = nw("TextButton", {
            Position = UDim2.fromOffset(72, 0), Size = UDim2.fromOffset(60, 28), Text = "Reset", AutoButtonColor = false,
            BorderSizePixel = 0, BackgroundColor3 = th.elem, TextColor3 = th.dim, TextSize = 12, Font = Enum.Font.GothamMedium
        }, ctl);
        crn(rsb, 7);
        local spb = nw("TextButton", {
            Position = UDim2.fromOffset(138, 0), Size = UDim2.fromOffset(52, 28), Text = "1.0x", AutoButtonColor = false,
            BorderSizePixel = 0, BackgroundColor3 = th.elem, TextColor3 = th.dim, TextSize = 12, Font = Enum.Font.GothamMedium
        }, ctl);
        crn(spb, 7);
        local tlab = tx(ctl, {
            Position = UDim2.new(0, 196, 0, 0), Size = UDim2.new(1, -196, 1, 0), Text = "0.00 / 0.00",
            TextColor3 = th.dim, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right
        });

        local tlw = nw("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1 }, GP.card);
        local trk = nw("TextButton", {
            Size = UDim2.new(1, 0, 0, 36), Text = "", AutoButtonColor = false, BackgroundColor3 = th.elem,
            BorderSizePixel = 0, ClipsDescendants = true
        }, tlw);
        crn(trk, 6);
        local bars = nw("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, trk);
        local ghost = nw("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 3 }, trk);
        crn(ghost, 3);
        local phd = nw("Frame", { Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = th.txt, BorderSizePixel = 0, ZIndex = 6 }, trk);
        tx(tlw, { Position = UDim2.fromOffset(0, 38), Size = UDim2.new(.5, 0, 0, 14), Text = "0.00s", TextColor3 = th.dim, TextSize = 10 });
        local t1l = tx(tlw, {
            Position = UDim2.new(.5, 0, 0, 38), Size = UDim2.new(.5, 0, 0, 14), Text = "0.00s",
            TextColor3 = th.dim, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right
        });

        local paintk, pfrom, pkey, listen = "Block", nil, Enum.KeyCode.E, false;
        local chipw = nw("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 }, GP.card);
        local CG = 5;
        nw("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, CG), SortOrder = Enum.SortOrder.LayoutOrder }, chipw);
        local chips = {};

        local function setchips()
            for k, c in chips do
                local on = k == paintk;
                c.s.Color = th.txt;
                c.s.Transparency = on and .05 or .78;
                c.t.TextColor3 = on and th.txt or th.dim;
            end;
        end;

        for i, k in KINDS do
            local f = nw("Frame", {
                Size = UDim2.new(1 / #KINDS, -CG * (#KINDS - 1) / #KINDS, 1, 0),
                LayoutOrder = i, BackgroundTransparency = 1, BorderSizePixel = 0
            }, chipw);
            crn(f, 5);
            local b = nw("TextButton", { Size = UDim2.fromScale(1, 1), Text = "", AutoButtonColor = false, BackgroundTransparency = 1 }, f);
            local l = tx(f, {
                Size = UDim2.fromScale(1, 1), Text = k, TextColor3 = th.dim, TextSize = 10,
                TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Center
            });
            local st = nw("UIStroke", { Color = th.txt, Transparency = .78, Thickness = 1 }, f);
            chips[k] = { f = f, t = l, s = st };
            b.MouseButton1Click:Connect(function()
                paintk = k;
                setchips();
            end);
        end;
        setchips();

        local mrow = nw("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, GP.card);
        local mkb = nw("TextButton", {
            Size = UDim2.new(1, -74, 1, 0), Text = "Mark Start", AutoButtonColor = false, BorderSizePixel = 0,
            BackgroundColor3 = th.elem, TextColor3 = th.txt, TextSize = 12, Font = Enum.Font.GothamMedium
        }, mrow);
        crn(mkb, 7);
        local keyb = nw("TextButton", {
            Position = UDim2.new(1, -70, 0, 0), Size = UDim2.fromOffset(70, 28), Text = pkey.Name, AutoButtonColor = false,
            BorderSizePixel = 0, BackgroundColor3 = th.elem, TextColor3 = th.dim, TextSize = 11, Font = Enum.Font.GothamMedium
        }, mrow);
        crn(keyb, 7);

        local function setmark()
            if pfrom then
                mkb.Text = string.format("Confirm %s  %.2fs", paintk, pfrom);
                mkb.BackgroundColor3 = KCOL[paintk];
                mkb.BackgroundTransparency = .25;
            else
                mkb.Text = "Mark Start";
                mkb.BackgroundColor3 = th.elem;
                mkb.BackgroundTransparency = 0;
            end;
        end;

        function drawbars()
            bars:ClearAllChildren();
            if not cur then return; end;
            local f = af.flags(cur);
            local n = #f;
            if n > 0 then
                local lh = math.max(4, math.floor(32 / n));
                for i, x in f do
                    local bb = math.clamp(x.b or 0, 0, curlen);
                    local ee = (x.e or -1) < 0 and curlen or math.clamp(x.e, 0, curlen);
                    if ee <= bb then ee = curlen; end;
                    local bar = nw("Frame", {
                        Position = UDim2.new(bb / curlen, 0, 0, 2 + (i - 1) * lh),
                        Size = UDim2.new((ee - bb) / curlen, 0, 0, lh - 2),
                        BackgroundColor3 = KCOL[x.k] or th.dim,
                        BackgroundTransparency = x.on and .1 or .74,
                        BorderSizePixel = 0
                    }, bars);
                    crn(bar, 3);
                end;
            end;
            for _, ht in curhits do
                if ht <= curlen then
                    local x = ht / curlen;
                    nw("Frame", {
                        Position = UDim2.new(x, -1, 0, 0), Size = UDim2.new(0, 2, 1, 0),
                        BackgroundColor3 = HITCOL, BorderSizePixel = 0, ZIndex = 4
                    }, bars);
                    local cp = nw("Frame", {
                        Position = UDim2.new(x, -3, 0, 0), Size = UDim2.fromOffset(6, 3),
                        BackgroundColor3 = HITCOL, BorderSizePixel = 0, ZIndex = 5
                    }, bars);
                    crn(cp, 1);
                end;
            end;
        end;

        local function setlen(l)
            curlen = math.max(l or 0, .05);
            t1l.Text = string.format("%.2fs", curlen);
            drawbars();
        end;

        local rig, anmr;
        local yaw, pitch, cdrag, cdist, cpiv = math.pi, -.05, false, 10, Vector3.new();

        local function camup()
            local o = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0) * CFrame.new(0, 0, cdist);
            cam.CFrame = CFrame.lookAt(cpiv + o.Position, cpiv);
        end;

        local function load3d()
            if rig then pcall(function() rig:Destroy(); end); rig, anmr = nil, nil; end;
            local ch = sv.lp.Character;
            if not ch then return false; end;
            local ok, cl = pcall(function() return ch:Clone(); end);
            if not ok or not cl then return false; end;
            for _, d in cl:GetDescendants() do
                if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then d:Destroy(); end;
            end;
            local hum = cl:FindFirstChildOfClass("Humanoid");
            if hum then
                hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
                hum.PlatformStand = true;
                anmr = hum:FindFirstChildOfClass("Animator") or nw("Animator", {}, hum);
            end;
            cl.Parent = wm;
            pcall(function() cl:PivotTo(CFrame.new()); end);
            local hrp = cl:FindFirstChild("HumanoidRootPart");
            if hrp then hrp.Anchored = true; end;
            rig = cl;
            local bcf, sz = cl:GetBoundingBox();
            cpiv = bcf.Position;
            cdist = math.max(sz.Y, sz.X) * 1.18;
            yaw, pitch = math.pi, -.05;
            camup();
            return anmr ~= nil;
        end;

        local function stoptrk()
            if curtrk then pcall(function() curtrk:Stop(0); curtrk:Destroy(); end); curtrk = nil; end;
        end;

        local function loadanim(path)
            stoptrk();
            local a = af.inst(path);
            if not (anmr and a) then return; end;
            local ok, tr = pcall(function() return anmr:LoadAnimation(a); end);
            if not ok or not tr then return; end;
            local t0 = os.clock();
            while tr.Length <= 0 and os.clock() - t0 < 2 do task.wait(); end;
            tr.Priority = Enum.AnimationPriority.Action4;
            tr.Looped = false;
            tr:Play(0);
            tr:AdjustSpeed(0);
            curtrk = tr;
            phead = 0;
            curhits = {};
            setlen(tr.Length);
            af.hits(path, function(h)
                if cur == path then
                    curhits = h;
                    drawbars();
                end;
            end);
        end;

        local function pick(path)
            cur = path;
            sel.Text = path or "no animation";
            sel.TextColor3 = path and th.txt or th.dim;
            playing = false;
            pb.Text = "Play";
            pb.TextColor3 = th.txt;
            pfrom = nil;
            setmark();
            if path then task.spawn(loadanim, path); end;
            drawflags();
        end;

        local rows = {};

        function rebuild()
            for _, r in rows do r:Destroy(); end;
            table.clear(rows);
            local list = af.paths(curset, sb.Text:lower());
            for i, path in list do
                local on = af.blocks(path);
                local btn = nw("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26), Text = "", AutoButtonColor = false, BorderSizePixel = 0,
                    BackgroundColor3 = th.elem2, BackgroundTransparency = 1, LayoutOrder = i
                }, sf);
                crn(btn, 6);
                local dot = nw("Frame", {
                    Position = UDim2.new(0, 9, .5, -3), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0,
                    BackgroundColor3 = on and th.act or th.dim, BackgroundTransparency = on and 0 or .45
                }, btn);
                crn(dot, 3);
                tx(btn, {
                    Position = UDim2.fromOffset(23, 0), Size = UDim2.new(1, -30, 1, 0),
                    Text = path, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd,
                    TextColor3 = cur == path and th.acc or (af.edited[path] and th.act or th.txt)
                });
                btn.MouseEnter:Connect(function() btn.BackgroundTransparency = .45; end);
                btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 1; end);
                btn.MouseButton1Click:Connect(function()
                    pick(path);
                    rebuild();
                end);
                rows[#rows + 1] = btn;
            end;
        end;

        sb:GetPropertyChangedSignal("Text"):Connect(function() rebuild(); end);

        local frows = {};

        local function touch()
            if not cur then return; end;
            af.commit(cur);
            drawbars();
            rebuild();
        end;

        local function pbox(par, idx, lab, val, set)
            local col = (idx - 1) % 3;
            local row = math.floor((idx - 1) / 3);
            local f = nw("Frame", {
                Position = UDim2.new(col / 3, col == 0 and 0 or 3, 0, row * 23),
                Size = UDim2.new(1 / 3, -3, 0, 21), BackgroundColor3 = th.elem2, BorderSizePixel = 0
            }, par);
            crn(f, 5);
            tx(f, { Position = UDim2.fromOffset(6, 0), Size = UDim2.new(0, 32, 1, 0), Text = lab, TextColor3 = th.dim, TextSize = 10 });
            local tb = nw("TextBox", {
                Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -44, 1, 0), BackgroundTransparency = 1,
                Text = val and tostring(val) or "", PlaceholderText = "-", PlaceholderColor3 = th.dim,
                TextColor3 = th.txt, TextSize = 11, Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false
            }, f);
            tb.FocusLost:Connect(function() set(tb.Text); end);
        end;

        function drawflags()
            for _, r in frows do r:Destroy(); end;
            table.clear(frows);
            if not cur then return; end;
            local f = af.flags(cur);
            for i, x in f do
                local par = KPAR[x.k];
                local np = par and #par or 0;
                local ph = np > 0 and (math.ceil(np / 3) * 23 + 3) or 0;
                local w = nw("Frame", { Size = UDim2.new(1, 0, 0, 26 + ph), BackgroundTransparency = 1, LayoutOrder = i }, GF.card);
                frows[#frows + 1] = w;

                local hd = nw("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = th.elem, BorderSizePixel = 0 }, w);
                crn(hd, 6);

                local dt = nw("TextButton", {
                    Position = UDim2.new(0, 8, .5, -4), Size = UDim2.fromOffset(8, 8), Text = "", AutoButtonColor = false,
                    BorderSizePixel = 0, BackgroundColor3 = KCOL[x.k] or th.dim, BackgroundTransparency = x.on and 0 or .7
                }, hd);
                crn(dt, 4);
                dt.MouseButton1Click:Connect(function()
                    x.on = not x.on;
                    drawflags();
                    touch();
                end);

                local kb = nw("TextButton", {
                    Position = UDim2.fromOffset(24, 0), Size = UDim2.fromOffset(74, 24), Text = x.k, AutoButtonColor = false,
                    BackgroundTransparency = 1, TextColor3 = th.txt, TextSize = 11, Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left
                }, hd);
                kb.MouseButton1Click:Connect(function()
                    local at = 1;
                    for j, k in KINDS do if k == x.k then at = j; break; end; end;
                    x.k = KINDS[(at % #KINDS) + 1];
                    drawflags();
                    touch();
                end);

                local function tbox(off, val, phh, set)
                    local bf = nw("Frame", {
                        Position = UDim2.new(1, off, .5, -9), Size = UDim2.fromOffset(50, 18),
                        BackgroundColor3 = th.elem2, BorderSizePixel = 0
                    }, hd);
                    crn(bf, 4);
                    local tb = nw("TextBox", {
                        Size = UDim2.new(1, -8, 1, 0), Position = UDim2.fromOffset(4, 0), BackgroundTransparency = 1,
                        Text = val, PlaceholderText = phh, PlaceholderColor3 = th.dim, TextColor3 = th.txt,
                        TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false
                    }, bf);
                    tb.FocusLost:Connect(function() set(tb.Text); end);
                end;

                tbox(-140, string.format("%.2f", x.b or 0), "0", function(v)
                    x.b = math.max(tonumber(v) or 0, 0);
                    drawflags();
                    touch();
                end);
                tx(hd, { Position = UDim2.new(1, -88, 0, 0), Size = UDim2.fromOffset(10, 24), Text = "-", TextColor3 = th.dim, TextSize = 11 });
                tbox(-78, (x.e or -1) < 0 and "end" or string.format("%.2f", x.e), "end", function(v)
                    x.e = tonumber(v) or -1;
                    drawflags();
                    touch();
                end);

                local xb = nw("TextButton", {
                    Position = UDim2.new(1, -22, .5, -9), Size = UDim2.fromOffset(18, 18), Text = "x", AutoButtonColor = false,
                    BackgroundColor3 = th.elem2, BorderSizePixel = 0, TextColor3 = th.dim, TextSize = 11, Font = Enum.Font.GothamMedium
                }, hd);
                crn(xb, 4);
                xb.MouseButton1Click:Connect(function()
                    table.remove(f, i);
                    drawflags();
                    touch();
                end);

                if np > 0 then
                    local pw = nw("Frame", { Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 0, ph), BackgroundTransparency = 1 }, w);
                    for j, sp in par do
                        local key = sp[2];
                        pbox(pw, j, sp[1], x[key], function(v)
                            x[key] = tonumber(v);
                            touch();
                        end);
                    end;
                end;
            end;
        end;

        local function mark()
            if not cur then return; end;
            if not pfrom then
                pfrom = phead;
                setmark();
                return;
            end;
            local a, b = pfrom, phead;
            if b < a then a, b = b, a; end;
            pfrom = nil;
            setmark();
            if b - a < .02 then return; end;
            local f = af.flags(cur);
            f[#f + 1] = { k = paintk, on = true, b = a, e = b >= curlen - .01 and -1 or b };
            drawflags();
            touch();
        end;

        mkb.MouseButton1Click:Connect(mark);
        keyb.MouseButton1Click:Connect(function()
            listen = true;
            keyb.Text = "...";
            keyb.TextColor3 = th.acc;
        end);

        ut.add(sv.uis.InputBegan:Connect(function(i, gp)
            if i.UserInputType ~= Enum.UserInputType.Keyboard then return; end;
            if listen then
                listen = false;
                pkey = i.KeyCode;
                keyb.Text = pkey.Name;
                keyb.TextColor3 = th.dim;
                return;
            end;
            if gp or not cur then return; end;
            if i.KeyCode == Enum.KeyCode.Escape then
                if pfrom then pfrom = nil; setmark(); end;
                return;
            end;
            if i.KeyCode == pkey then mark(); end;
        end));

        local function seek(x)
            local ap, as = trk.AbsolutePosition, trk.AbsoluteSize;
            if as.X <= 0 then return; end;
            phead = math.clamp((x - ap.X) / as.X, 0, 1) * curlen;
        end;

        trk.InputBegan:Connect(function(i)
            local t = i.UserInputType;
            if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                drag = true;
                seek(i.Position.X);
            end;
        end);

        local vpb = nw("TextButton", { Size = UDim2.fromScale(1, 1), Text = "", AutoButtonColor = false, BackgroundTransparency = 1 }, vpw);
        local lastm;
        vpb.InputBegan:Connect(function(i)
            local t = i.UserInputType;
            if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                cdrag = true;
                lastm = i.Position;
            end;
        end);

        ut.add(sv.uis.InputChanged:Connect(function(i)
            local t = i.UserInputType;
            if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return; end;
            if drag then seek(i.Position.X); end;
            if cdrag then
                local d = i.Position - (lastm or i.Position);
                lastm = i.Position;
                yaw -= d.X * .01;
                pitch = math.clamp(pitch - d.Y * .008, -1.2, 1.2);
                camup();
            end;
        end));

        ut.add(sv.uis.InputEnded:Connect(function(i)
            local t = i.UserInputType;
            if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                drag = false;
                cdrag = false;
            end;
        end));

        pb.MouseButton1Click:Connect(function()
            playing = not playing;
            pb.Text = playing and "Pause" or "Play";
            pb.TextColor3 = playing and th.act or th.txt;
        end);

        rsb.MouseButton1Click:Connect(function()
            phead = 0;
            playing = false;
            pb.Text = "Play";
            pb.TextColor3 = th.txt;
        end);

        local SPD, si = { 1, .5, .25, .1, 2 }, 1;
        spb.MouseButton1Click:Connect(function()
            si = (si % #SPD) + 1;
            spd = SPD[si];
            spb.Text = string.format("%.2gx", spd);
        end);

        ut.add(sv.runs.RenderStepped:Connect(function(dt)
            if not curtrk then return; end;
            if playing and not drag then
                phead += dt * spd;
                if phead >= curlen then phead = 0; end;
            end;
            curtrk.TimePosition = math.clamp(phead, 0, math.max(curlen - .001, 0));
            phd.Position = UDim2.new(math.clamp(phead / curlen, 0, 1), -1, 0, 0);
            tlab.Text = string.format("%.2f / %.2f", phead, curlen);
            if pfrom then
                local a, b = pfrom, phead;
                if b < a then a, b = b, a; end;
                ghost.Position = UDim2.new(a / curlen, 0, 0, 0);
                ghost.Size = UDim2.new((b - a) / curlen, 0, 1, 0);
                ghost.BackgroundColor3 = KCOL[paintk];
                ghost.BackgroundTransparency = .6;
                ghost.Visible = true;
            elseif ghost.Visible then
                ghost.Visible = false;
            end;
        end));

        local GA = AFF:Group({ Name = "Filter", Side = 1 });
        GA:Button({ Name = "Add Flag", Callback = function()
            if not cur then return; end;
            local f = af.flags(cur);
            f[#f + 1] = { k = paintk, on = true, b = 0, e = -1 };
            drawflags();
            touch();
        end });
        GA:Button({ Name = "Reset Animation", Callback = function()
            if not cur then return; end;
            af.revert(cur);
            drawflags();
            drawbars();
            rebuild();
        end });
        local function cfgpath()
            local n = lib.cfgname;
            if not (n and lib.cfgd) then return nil; end;
            return lib.cfgd .. "/" .. n .. ".json";
        end;

        GA:Button({ Name = "Save", Callback = function()
            local ok = af.save();
            local cp = cfgpath();
            if cp then ok = af.tocfg(cp) or ok; end;
            note("Anim Filter", ok and (af.count() .. " saved" .. (cp and " to " .. lib.cfgname or "")) or "save failed", "film");
        end });
        GA:Button({ Name = "Reset All", Callback = function()
            af.clear();
            pick(cur);
            rebuild();
            note("Anim Filter", "filter restored", "film");
        end });
        GA:Button({ Name = "Reload Model", Callback = function()
            if load3d() and cur then task.spawn(loadanim, cur); end;
        end });

        do
            local os2, ol2 = lib.SaveCfg, lib.LoadCfg;
            if type(os2) == "function" and type(ol2) == "function" then
                lib.SaveCfg = function(self, n)
                    local ok, e = os2(self, n);
                    if ok then pcall(af.tocfg, self.cfgd .. "/" .. n .. ".json"); end;
                    return ok, e;
                end;
                lib.LoadCfg = function(self, n)
                    local ok, e = ol2(self, n);
                    if ok then
                        pcall(af.fromcfg, self.cfgd .. "/" .. n .. ".json");
                        pick(cur);
                        rebuild();
                    end;
                    return ok, e;
                end;
            end;
        end;

        load3d();
        ut.add(sv.lp.CharacterAdded:Connect(function()
            task.delay(1.5, function()
                if load3d() and cur then task.spawn(loadanim, cur); end;
            end);
        end));

        if fl.ready then
            rebuild();
        else
            task.spawn(function()
                for _ = 1, 200 do
                    if fl.ready then break; end;
                    task.wait(.1);
                end;
                mdd:SetValues(af.sets(), true);
                rebuild();
            end);
        end;
    end;
    if afp and af then buildaf(); end;

    if lib.flags.ABPunish or lib.flags.ABDashPunish or lib.flags.M1Catch then bk.start(); end;
    if bbk then bbk.sync(); end;
    if mo and lib.flags.MobileBtns then mo.sync(); end;
    return { lib = lib, window = win };
end;

end)();

local old = rawget(_G, "jjs");
if old and old.unload then pcall(old.unload); end;

local lrm = {};
do
    pcall(function()
        lrm.prem, lrm.secs, lrm.runs = LRM_IsUserPremium, LRM_SecondsLeft, LRM_TotalExecutions;
        lrm.note, lrm.disc, lrm.ver = LRM_Note or LRM_UserNote, LRM_LinkedDiscordID, LRM_ScriptVersion;
    end);
    local g = type(getgenv) == "function" and getgenv() or nil;
    local nm = { prem = "LRM_IsUserPremium", secs = "LRM_SecondsLeft", runs = "LRM_TotalExecutions", note = "LRM_UserNote", disc = "LRM_LinkedDiscordID", ver = "LRM_ScriptVersion" };
    for f, n in nm do
        if lrm[f] == nil then
            local v = rawget(_G, n);
            if v == nil and g then v = rawget(g, n); end;
            lrm[f] = v;
        end;
    end;
end;

local ctx = { lrm = lrm };
ctx.svc = _M1();
ctx.ut = _M2(ctx);
ctx.cfg = _M3(ctx);
ctx.caps = _M4(ctx);
ctx.key = _M5(ctx);

do local ok, m = pcall(_M6, ctx); if ok then ctx.filter = m; else ctx.ut.warn("init", "filter ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M7, ctx); if ok then ctx.doors = m; else ctx.ut.warn("init", "doors ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M8, ctx); if ok then ctx.act = m; else ctx.ut.warn("init", "act ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M9, ctx); if ok then ctx.track = m; else ctx.ut.warn("init", "track ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M10, ctx); if ok then ctx.lock = m; else ctx.ut.warn("init", "lock ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M11, ctx); if ok then ctx.bfc = m; else ctx.ut.warn("init", "bfc ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M12, ctx); if ok then ctx.block = m; else ctx.ut.warn("init", "block ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M13, ctx); if ok then ctx.sda = m; else ctx.ut.warn("init", "sda ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M14, ctx); if ok then ctx.misc = m; else ctx.ut.warn("init", "misc ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M15, ctx); if ok then ctx.mobile = m; else ctx.ut.warn("init", "mobile ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M16, ctx); if ok then ctx.combo = m; else ctx.ut.warn("init", "combo ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M17, ctx); if ok then ctx.aura = m; else ctx.ut.warn("init", "aura ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M18, ctx); if ok then ctx.anti = m; else ctx.ut.warn("init", "anti ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M19, ctx); if ok then ctx.bypass = m; else ctx.ut.warn("init", "bypass ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M20, ctx); if ok then ctx.esp = m; else ctx.ut.warn("init", "esp ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M21, ctx); if ok then ctx.invis = m; else ctx.ut.warn("init", "invis ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M22, ctx); if ok then ctx.vote = m; else ctx.ut.warn("init", "vote ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M23, ctx); if ok then ctx.avatar = m; else ctx.ut.warn("init", "avatar ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M24, ctx); if ok then ctx.bbreak = m; else ctx.ut.warn("init", "bbreak ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M25, ctx); if ok then ctx.legacy = m; else ctx.ut.warn("init", "legacy ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M26, ctx); if ok then ctx.piano = m; else ctx.ut.warn("init", "piano ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M27, ctx); if ok then ctx.fly = m; else ctx.ut.warn("init", "fly ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M28, ctx); if ok then ctx.parkour = m; else ctx.ut.warn("init", "parkour ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M29, ctx); if ok then ctx.respawn = m; else ctx.ut.warn("init", "respawn ctor failed: " .. tostring(m)); end; end;
do local ok, m = pcall(_M30, ctx); if ok then ctx.animf = m; else ctx.ut.warn("init", "animf ctor failed: " .. tostring(m)); end; end;

ctx.track.start();

do
    local sti = setthreadidentity or setidentity;
    if sti then pcall(sti, 8); end;
    local ok, err = pcall(function() ctx.ui = _M31(ctx); end);
    if sti then pcall(sti, 7); end;
    if not ok then ctx.ut.warn("init", "ui failed: " .. tostring(err)); end;
end;

if ctx.anti then task.delay(1.5, function() pcall(ctx.anti.set, true); end); end;

function ctx.stopall()
    if ctx.block then pcall(ctx.block.stop); end;
    if ctx.bfc then pcall(ctx.bfc.stop); pcall(ctx.bfc.abfstop); end;
    if ctx.lock then pcall(ctx.lock.stop); end;
    if ctx.misc then pcall(ctx.misc.unload); end;
    if ctx.sda then pcall(ctx.sda.stop); end;
    if ctx.bbreak then pcall(ctx.bbreak.stop); end;
    if ctx.combo then pcall(ctx.combo.stop); end;
    if ctx.aura then pcall(ctx.aura.stop); end;
    if ctx.mobile then pcall(ctx.mobile.stop); end;
    if ctx.track then pcall(ctx.track.stop); end;
    if ctx.anti then pcall(ctx.anti.stop); end;
    if ctx.bypass then pcall(ctx.bypass.unhook); end;
    if ctx.esp then pcall(ctx.esp.stop); end;
    if ctx.invis then pcall(ctx.invis.stop); end;
    if ctx.vote then pcall(ctx.vote.stop); end;
    if ctx.piano then pcall(ctx.piano.stop); end;
    if ctx.fly then pcall(ctx.fly.stop); end;
    if ctx.parkour then pcall(ctx.parkour.stop); end;
    if ctx.respawn then pcall(ctx.respawn.stop); end;
    if ctx.animf then pcall(ctx.animf.stop); end;
end;

function ctx.unload(skipui)
    if ctx.dead then return; end;
    ctx.dead = true;
    rawset(_G, "jjs", nil);
    pcall(ctx.stopall);
    if not skipui and ctx.lib then pcall(ctx.lib.Unload, ctx.lib); end;
    pcall(ctx.ut.unload);
end;

function ctx.status()
    return {
        filter = ctx.filter and ctx.filter.ready,
        anims = ctx.filter and #ctx.filter.allpaths or 0,
        chain = ctx.bfc and ctx.bfc.en or false,
        ping = ctx.track and ctx.track.sping() or 0,
        fps = ctx.track and ctx.track.fps() or 0,
    };
end;

rawset(_G, "jjs", ctx);
return ctx;
