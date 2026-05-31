local SS = _G._SS
local C  = SS.C
local Frm,Lbl,Btn,Inp,Con,Scr,hov,tw = SS.Frm,SS.Lbl,SS.Btn,SS.Inp,SS.Con,SS.Scr,SS.hov,SS.tw
local corner,stroke,listH,listV,pad,rowBar = SS.corner,SS.stroke,SS.listH,SS.listV,SS.pad,SS.rowBar
local FB,FN,FC = SS.FB,SS.FN,SS.FC

local P = SS.newTab("📜","Scripts")

Lbl(P, "SCRIPT HUB", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

-- Search bar
local sRow = rowBar(P, 18)
local SrchBox = Inp(P, "Search scripts...", UDim2.new(1,-96,0,26), UDim2.new(0,0,0,20))
SrchBox.MultiLine = false; SrchBox.TextSize = 12
local BFetch = Btn(sRow, "🔍 Search", UDim2.new(0,88,1,0), nil, C.ACC)
BFetch.LayoutOrder = 2
hov(BFetch, C.ACC, C.ACCHV)

-- Output console
local SOut = Con(P, UDim2.new(1,0,0,60), UDim2.new(0,0,1,-62))
local function sOut(msg, ok2)
    SOut.TextColor3 = ok2 and C.GREEN or C.RED; SOut.Text = tostring(msg)
end

-- Script list
local ScriptScr = Scr(P, UDim2.new(1,0,1,-100), UDim2.new(0,0,0,50)); listV(ScriptScr, 4)

local BUILTIN = {
    {name="Infinite Yield",   url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"},
    {name="Dark Hub",         url="https://raw.githubusercontent.com/RandomAdamYT/DarkHub/main/main.lua"},
    {name="SimpleSpy",        url="https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua"},
    {name="Dex Explorer",     url="https://raw.githubusercontent.com/LorekeeperZinnia/Dex/master/Dex3.1.lua"},
    {name="Hydroxide",        url="https://raw.githubusercontent.com/violets-blue/Hydroxide/main/init.lua"},
    {name="Unnamed ESP",      url="https://raw.githubusercontent.com/ic3w0lf22/Unnamed-ESP/master/UnnamedESP.lua"},
    {name="Fluent Library",   url="https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Fluent.lua"},
    {name="Prison Life GUI",  url="https://raw.githubusercontent.com/1201for/V3rm-Prison-Life/master/VisualV3rmHack.lua"},
    {name="OPWeaponizer",     url="https://raw.githubusercontent.com/Stefanuk12/OP-Admin/master/Source.lua"},
}

local function addScriptRow(entry)
    local Row = Frm(ScriptScr, UDim2.new(1,-4,0,48), nil, C.PANEL)
    corner(Row, 7); stroke(Row, Color3.fromRGB(35,48,88), 1)
    Lbl(Row, entry.name, UDim2.new(1,-110,0,24), UDim2.new(0,10,0,5), C.TXT, FB, 13)
    Lbl(Row, entry.url:sub(1,50).."...", UDim2.new(1,-110,0,16), UDim2.new(0,10,0,26), C.TXTS, FN, 10)

    local BRun  = Btn(Row, "▶ Run",  UDim2.new(0,48,0,20), UDim2.new(1,-104,0.5,-10), C.ACC)
    local BCopy = Btn(Row, "Copy",   UDim2.new(0,44,0,20), UDim2.new(1,-52,0.5,-10),  C.GREY)
    hov(BRun, C.ACC, C.ACCHV); hov(BCopy, C.GREY, C.GRYHV)
    BRun.TextSize = 11; BCopy.TextSize = 11

    BRun.MouseButton1Click:Connect(function()
        sOut("Fetching "..entry.name.."...", true)
        task.spawn(function()
            local ok, src = pcall(game.HttpGet, game, entry.url, true)
            if not ok then sOut("HTTP fail: "..tostring(src), false); return end
            local ld = loadstring or load
            local fn, ce = ld(src)
            if not fn then sOut("Compile fail:\n"..tostring(ce), false); return end
            local ok2, re = pcall(fn)
            sOut(ok2 and (entry.name.." loaded ✓") or ("Error:\n"..tostring(re)), ok2)
        end)
    end)

    BCopy.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(entry.url); sOut("URL copied.", true)
        else
            sOut("setclipboard not available.", false)
        end
    end)
end

-- Populate builtin scripts
for _, entry in BUILTIN do addScriptRow(entry) end

-- Search via ScriptBlox
BFetch.MouseButton1Click:Connect(function()
    local query = SrchBox.Text:match("^%s*(.-)%s*$")
    if query == "" then sOut("Enter a search term.", false); return end
    sOut("Searching ScriptBlox for: "..query.."...", true)
    task.spawn(function()
        local ok, res = pcall(game.HttpGet, game,
            "https://scriptblox.com/api/script/search?q="..query:gsub(" ", "+").."&max=10&mode=free", true)
        if not ok then sOut("Search failed: "..tostring(res), false); return end
        local ok2, data = pcall(function()
            -- parse JSON manually (minimal, no library)
            local results = {}
            for title, rawScript in res:gmatch('"title"%s*:%s*"([^"]+)"[^}]+"rawScript"%s*:%s*"([^"]+)"') do
                results[#results+1] = {name=title, url=rawScript}
            end
            return results
        end)
        if not ok2 or #data == 0 then
            sOut("No results or parse error.", false); return
        end
        -- Clear existing and add results
        for _, ch in ScriptScr:GetChildren() do
            if not ch:IsA("UIListLayout") then ch:Destroy() end
        end
        for _, entry in data do addScriptRow(entry) end
        sOut("Found "..#data.." scripts.", true)
    end)
end)
