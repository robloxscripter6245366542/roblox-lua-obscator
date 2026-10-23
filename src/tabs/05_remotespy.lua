-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 5 — REMOTE SPY
--  Hooks __namecall · Live log · Filter · Block list · Export
-- ═══════════════════════════════════════════════════════════════════════════════
local P5 = newTab("📡", "RemoteSpy")
L(P5, "REMOTE SPY", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

-- ── Status bar ────────────────────────────────────────────────────────────────
local statusF = F(P5, UDim2.new(1,0,0,24), UDim2.new(0,0,0,18), C.PANEL); corner(statusF,6)
local spyStatusLbl = L(statusF, "● Inactive", UDim2.new(0.5,0,1,0), nil, C.RED, FB, 11)
local spyCountLbl  = L(statusF, "Captured: 0", UDim2.new(0.5,0,1,0), UDim2.new(0.5,0,0,0),
    C.TXTS, FN, 11, Enum.TextXAlignment.Right)

-- ── Controls ──────────────────────────────────────────────────────────────────
local rRow     = rowBar(P5, 46, 26)
local BSpyOn   = B(rRow, "▶ Start",  UDim2.new(0,88,1,0), nil, C.GRN)
local BSpyOff  = B(rRow, "■ Stop",   UDim2.new(0,80,1,0), nil, C.GREY)
local BSpyClr  = B(rRow, "Clear",    UDim2.new(0,68,1,0), nil, C.GREY)
local BSpyExp  = B(rRow, "Export",   UDim2.new(0,76,1,0), nil, C.BLUE)
local BSpyCopy = B(rRow, "Copy All", UDim2.new(0,82,1,0), nil, C.GREY)
styleRow({BSpyOn,BSpyOff,BSpyClr,BSpyExp,BSpyCopy})
hov(BSpyOn,   C.GRN,  C.GRNHV); hov(BSpyOff, C.GREY, C.GRYHV)
hov(BSpyClr,  C.GREY, C.GRYHV); hov(BSpyExp,  C.BLUE, C.BLHV)
hov(BSpyCopy, C.GREY, C.GRYHV)

-- ── Filter row ────────────────────────────────────────────────────────────────
local filtF = F(P5, UDim2.new(1,0,0,26), UDim2.new(0,0,0,76), C.PANEL); corner(filtF,6)
L(filtF, "Filter:", UDim2.new(0,44,1,0), UDim2.new(0,6,0,0), C.TXTS, FN, 11)
local SpyFiltIn = INS(filtF, "(leave blank = capture all)", UDim2.new(0.72,0,0,20), UDim2.new(0,54,0,3))

-- Method filter toggles
local methF = F(P5, UDim2.new(1,0,0,24), UDim2.new(0,0,0,106), C.PANEL); corner(methF,6)
listH(methF, 3); pad(methF, 2, 4)
local METHODS = {"FireServer","InvokeServer","FireAllClients","FireClient","InvokeClient"}
local methActive = {}
for _, m in METHODS do methActive[m] = true end
for i, m in METHODS do
    local short = m:gsub("Server","Srv"):gsub("Client","Cli"):gsub("All","All")
    local b = B(methF, short, UDim2.new(0,98,1,0), nil, C.ACC); b.TextSize=9
    b.LayoutOrder = i; hov(b, C.ACC, C.ACCHV)
    b.MouseButton1Click:Connect(function()
        methActive[m] = not methActive[m]
        tw(b, {BackgroundColor3 = methActive[m] and C.ACC or C.GREY})
    end)
end

-- ── Log scroll ────────────────────────────────────────────────────────────────
local SpyScr = SCR(P5, UDim2.new(1,0,1,-136), UDim2.new(0,0,0,134))
listV(SpyScr, 2)

-- ── State ─────────────────────────────────────────────────────────────────────
local spyActive  = false
local spyHooked  = false
local spyLog     = {}
local blockedSet = {}
local spyFilter  = ""

SpyFiltIn:GetPropertyChangedSignal("Text"):Connect(function()
    spyFilter = SpyFiltIn.Text:lower()
end)

-- Color per method
local MCOL = {
    FireServer     = C.ORAN,
    InvokeServer   = C.PURP,
    FireAllClients = C.RED,
    FireClient     = C.PINK,
    InvokeClient   = C.TEAL,
}

local function addSpyRow(entry)
    -- apply filter
    if spyFilter ~= "" and not entry.remote:lower():find(spyFilter, 1, true) then return end
    if not methActive[entry.method] then return end
    if blockedSet[entry.remote] then return end

    local Row = F(SpyScr, UDim2.new(1,-4,0,40), nil, C.PANEL); corner(Row,5)
    stroke(Row, Color3.fromRGB(28,40,72), 1)

    local mc = MCOL[entry.method] or C.TXTS
    local bg = pill(Row, entry.method, mc, UDim2.new(0,90,0,16), UDim2.new(0,4,0.5,-8))
    L(Row, entry.remote, UDim2.new(1,-200,0,18), UDim2.new(0,98,0,2), C.TXT, FN, 12)
    L(Row, os.date("%H:%M:%S", entry.ts),
        UDim2.new(0,64,0,14), UDim2.new(1,-80,0,2), C.TXTD, FC, 10, Enum.TextXAlignment.Right)

    local argsPreview = ""
    if #entry.args > 0 then
        local parts = {}
        for i, a in ipairs(entry.args) do
            if i > 4 then parts[#parts+1]="…"; break end
            parts[#parts+1] = tostring(a):sub(1,30)
        end
        argsPreview = table.concat(parts, ", ")
    end
    L(Row, "Args: " .. argsPreview, UDim2.new(1,-100,0,14), UDim2.new(0,98,0,22), C.TXTS, FC, 10)

    local BCp  = B(Row,"Copy",  UDim2.new(0,36,0,16), UDim2.new(1,-80,0.5,-8), C.GREY)
    local BBlk = B(Row,"Block", UDim2.new(0,36,0,16), UDim2.new(1,-40,0.5,-8), C.RED)
    BCp.TextSize=9; BBlk.TextSize=9; hov(BCp,C.GREY,C.GRYHV); hov(BBlk,C.RED,C.REDHV)
    BCp.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(entry.method .. " → " .. entry.remote .. "\nArgs: " .. argsPreview)
        end
    end)
    BBlk.MouseButton1Click:Connect(function()
        blockedSet[entry.remote] = true
        Row:Destroy()
        spyStatusLbl.Text = "Blocked: " .. entry.remote
    end)
end

local function startSpy()
    if spyHooked then
        spyActive = true
        spyStatusLbl.Text = "● Active"; spyStatusLbl.TextColor3 = C.GRN; return
    end
    if not hookmetamethod    then spyStatusLbl.Text="✗ hookmetamethod missing"; spyStatusLbl.TextColor3=C.RED; return end
    if not getnamecallmethod then spyStatusLbl.Text="✗ getnamecallmethod missing"; spyStatusLbl.TextColor3=C.RED; return end

    spyActive = true; spyHooked = true
    spyStatusLbl.Text = "● Active"; spyStatusLbl.TextColor3 = C.GRN
    tw(BSpyOn, {BackgroundColor3=C.GREY}); tw(BSpyOff, {BackgroundColor3=C.RED})

    local _old; _old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local capture = spyActive and methActive[method]
        if capture then
            local args = {...}
            local rname = tostring(self):match("^(.+) %(") or tostring(self)
            local entry = {remote=rname, method=method, args=args, ts=os.time()}
            table.insert(spyLog, 1, entry)
            if #spyLog > 500 then table.remove(spyLog) end
            spyCountLbl.Text = "Captured: " .. #spyLog
            task.spawn(addSpyRow, entry)
        end
        return _old(self, ...)
    end)
end

BSpyOn.MouseButton1Click:Connect(startSpy)

BSpyOff.MouseButton1Click:Connect(function()
    spyActive = false
    spyStatusLbl.Text = "◉ Paused"; spyStatusLbl.TextColor3 = C.YELL
    tw(BSpyOff, {BackgroundColor3=C.GREY})
end)

BSpyClr.MouseButton1Click:Connect(function()
    clearLayout(SpyScr)
    spyLog = {}; spyCountLbl.Text = "Captured: 0"
end)

BSpyExp.MouseButton1Click:Connect(function()
    if not writefile then spyStatusLbl.Text="writefile unavailable"; return end
    local lines = {}
    for _, e in spyLog do
        lines[#lines+1] = os.date("%Y-%m-%d %H:%M:%S", e.ts) ..
            " | " .. e.method .. " | " .. e.remote
    end
    local fname = "nexus_remotespy_" .. os.time() .. ".txt"
    writefile(fname, table.concat(lines, "\n"))
    spyStatusLbl.Text = "Exported → " .. fname; spyStatusLbl.TextColor3 = C.GRN
end)

BSpyCopy.MouseButton1Click:Connect(function()
    if not setclipboard then return end
    local lines = {}
    for i = 1, math.min(50, #spyLog) do
        local e = spyLog[i]
        lines[#lines+1] = e.method .. " | " .. e.remote
    end
    setclipboard(table.concat(lines, "\n"))
    spyStatusLbl.Text = "Copied " .. #lines .. " entries"; spyStatusLbl.TextColor3 = C.GRN
end)
