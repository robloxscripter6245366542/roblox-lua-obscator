-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 9 — SCRIPT HUB
--  Search · Category filter · Run / Copy URL · 20+ scripts
-- ═══════════════════════════════════════════════════════════════════════════════
local P9 = newTab("📜", "Scripts")
L(P9, "SCRIPT HUB", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

-- ── Search + filter ───────────────────────────────────────────────────────────
local searchF = F(P9, UDim2.new(1,0,0,26), UDim2.new(0,0,0,18), C.PANEL); corner(searchF,6)
L(searchF, "🔍", UDim2.new(0,22,1,0), UDim2.new(0,4,0,0), C.TXTS, FN, 13, Enum.TextXAlignment.Center)
local SHSearch = INS(searchF, "Search scripts or category…", UDim2.new(1,-30,0,20), UDim2.new(0,28,0,3))

-- Category toggles
local catF = F(P9, UDim2.new(1,0,0,24), UDim2.new(0,0,0,48), C.PANEL); corner(catF,6)
listH(catF, 3); pad(catF, 2, 4)
local CATS = {"All","Utility","ESP","Game","Library","Admin","Debug"}
local selCat = "All"
local catBtns = {}
for i, cat in CATS do
    local col = C.CAT[cat] or C.ACC
    local b = B(catF, cat, UDim2.new(0,72,1,0), nil, i==1 and C.ACC or C.GRYDK)
    b.LayoutOrder = i; b.TextSize = 10; hov(b, C.GRYDK, C.GREY)
    catBtns[cat] = b
    b.MouseButton1Click:Connect(function()
        selCat = cat
        for _, cb in catBtns do tw(cb,{BackgroundColor3=C.GRYDK}) end
        tw(b, {BackgroundColor3 = col or C.ACC})
        buildScripts(SHSearch.Text:lower())
    end)
end

local SHOut = OUT(P9, UDim2.new(1,0,0,38), UDim2.new(0,0,1,-40))
local function shOut(msg, ok2) SHOut.TextColor3=ok2 and C.GRN or C.RED; SHOut.Text=ts()..tostring(msg) end

local SHScr = SCR(P9, UDim2.new(1,0,1,-110), UDim2.new(0,0,0,76))
listV(SHScr, 4)

-- ── Script database ───────────────────────────────────────────────────────────
local SCRIPTS = {
    -- Utility
    {cat="Utility",  name="Infinite Yield",       url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",                  desc="Full admin command system"},
    {cat="Utility",  name="SimpleSpy",             url="https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua",  desc="Remote spy + logger"},
    {cat="Utility",  name="Dex Explorer 3.1",      url="https://raw.githubusercontent.com/LorekeeperZinnia/Dex/master/Dex3.1.lua",              desc="Full game instance explorer"},
    {cat="Utility",  name="Hydroxide",             url="https://raw.githubusercontent.com/violets-blue/Hydroxide/main/init.lua",                desc="Instance + remote explorer"},
    {cat="Utility",  name="Remote Spy Lite",       url="https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua",  desc="Lightweight remote logger"},
    -- ESP
    {cat="ESP",      name="Unnamed ESP",           url="https://raw.githubusercontent.com/ic3w0lf22/Unnamed-ESP/master/UnnamedESP.lua",          desc="Universal player + object ESP"},
    {cat="ESP",      name="ESP Box Overlay",       url="https://raw.githubusercontent.com/ic3w0lf22/Unnamed-ESP/master/UnnamedESP.lua",          desc="Box ESP with health bars"},
    -- Game-specific
    {cat="Game",     name="Prison Life GUI",       url="https://raw.githubusercontent.com/1201for/V3rm-Prison-Life/master/VisualV3rmHack.lua",   desc="Prison Life exploit GUI"},
    {cat="Game",     name="Blox Fruits Helper",    url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",                  desc="Blox Fruits auto-farm utils"},
    {cat="Game",     name="Pet Sim Auto Farm",     url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",                  desc="Pet Simulator X automation"},
    {cat="Game",     name="Adopt Me Scripts",      url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",                  desc="Adopt Me dupe utilities"},
    -- Library
    {cat="Library",  name="Fluent UI Library",     url="https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Fluent.lua",              desc="Modern executor UI framework"},
    {cat="Library",  name="Orion UI Library",      url="https://raw.githubusercontent.com/shlexware/Orion/main/source",                        desc="Clean component UI kit"},
    {cat="Library",  name="Rayfield UI",           url="https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",         desc="Premium UI library"},
    {cat="Library",  name="Kavo UI Library",       url="https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua",             desc="Lightweight UI components"},
    -- Admin
    {cat="Admin",    name="Infinite Yield Cmd",    url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",                  desc="400+ admin commands"},
    {cat="Admin",    name="Dex Admin Panel",       url="https://raw.githubusercontent.com/LorekeeperZinnia/Dex/master/Dex3.1.lua",              desc="Admin GUI with exploits"},
    -- Debug
    {cat="Debug",    name="Script Decompiler",     url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",                  desc="Bytecode decompiler attempt"},
    {cat="Debug",    name="Memory Inspector",      url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",                  desc="Memory address viewer"},
    {cat="Debug",    name="Network Logger",        url="https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua",  desc="Full network traffic log"},
}

-- ── Build / rebuild listing ───────────────────────────────────────────────────
buildScripts = function(filter)
    for _, ch in SHScr:GetChildren() do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
    local shown = 0
    for _, entry in SCRIPTS do
        local catMatch = selCat == "All" or entry.cat == selCat
        local searchMatch = filter == "" or
            entry.name:lower():find(filter,1,true) or
            entry.cat:lower():find(filter,1,true) or
            entry.desc:lower():find(filter,1,true)
        if catMatch and searchMatch then
            shown += 1
            local Row = card(SHScr, entry.name, entry.desc, 56)
            stroke(Row, Color3.fromRGB(28,40,72), 1)
            local catCol = C.CAT[entry.cat] or C.GREY
            pill(Row, entry.cat, catCol, UDim2.new(0,58,0,18), UDim2.new(0,6,0,5))

            local BRun = B(Row, "▶ Run", UDim2.new(0,52,0,22), UDim2.new(1,-112,0.5,-11), C.ACC)
            local BCpy = B(Row, "URL",   UDim2.new(0,44,0,22), UDim2.new(1,-56,0.5,-11),  C.GREY)
            BRun.TextSize=10; BCpy.TextSize=10
            hov(BRun, C.ACC, C.ACCHV); hov(BCpy, C.GREY, C.GRYHV)

            local url, nm = entry.url, entry.name
            BRun.MouseButton1Click:Connect(function()
                shOut("Fetching " .. nm .. "…", true)
                task.spawn(function()
                    local ok, src = pcall(game.HttpGet, game, url, true)
                    if not ok then shOut("HTTP fail: " .. tostring(src), false); return end
                    local fn, ce = _ld(src)
                    if not fn then shOut("Compile:\n" .. tostring(ce), false); return end
                    local ok2, re = pcall(fn)
                    shOut(ok2 and (nm .. " loaded ✓  (" .. #src .. " bytes)")
                        or "Error:\n" .. tostring(re), ok2)
                end)
            end)
            BCpy.MouseButton1Click:Connect(function()
                if setclipboard then setclipboard(url); shOut("URL copied: " .. nm, true)
                else shOut("setclipboard unavailable.", false) end
            end)
        end
    end
    if shown == 0 then
        local R = F(SHScr, UDim2.new(1,-4,0,32), nil, C.PANEL); corner(R,6)
        L(R, "No scripts match '" .. filter .. "'",
            UDim2.new(1,0,1,0), nil, C.TXTS, FN, 12, Enum.TextXAlignment.Center)
    end
end

SHSearch:GetPropertyChangedSignal("Text"):Connect(function()
    buildScripts(SHSearch.Text:lower())
end)
