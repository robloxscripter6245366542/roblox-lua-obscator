-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 1 — EXECUTE
--  5 modes: Client LS · Server LS · Require · URL Exec · File Exec
--  Features: 30-entry history, line counter, output timestamps
-- ═══════════════════════════════════════════════════════════════════════════════
local P1 = newTab("▶", "Execute")

-- ── Mode selector ─────────────────────────────────────────────────────────────
local mRow  = rowBar(P1, 0, 26)
local MODES = {"Client LS","Server LS","Require","URL Exec","File Exec"}
local mBtns = {}
local curMode = 1

local function setMode(i)
    curMode = i
    for j, b in mBtns do
        tw(b, {BackgroundColor3 = j==i and C.BLUE or C.EDIT})
        b.TextColor3 = j==i and C.TXT or C.TXTS
    end
end

for i, nm in MODES do
    local w = i == 1 and 108 or (i <= 3 and 90 or 98)
    local b = B(mRow, nm, UDim2.new(0,w,1,0), nil, i==1 and C.BLUE or C.EDIT, C.TXTS)
    b.LayoutOrder = i; b.TextSize = 11
    hov(b, C.EDIT, C.BLHV)
    b.MouseButton1Click:Connect(function() setMode(i) end)
    mBtns[i] = b
end

-- Mode descriptions shown below the bar
local modeDesc = {
    "Runs code client-side via loadstring/load",
    "Runs code server-side via SS_ExecBridge",
    "Loads a Roblox Module by asset ID",
    "Fetches raw URL then executes client-side",
    "Reads a local file then executes (readfile)",
}
local ModeInfo = L(P1, modeDesc[1], UDim2.new(1,0,0,13), UDim2.new(0,0,0,28), C.TXTD, FN, 10)

for i, b in mBtns do
    b.MouseButton1Click:Connect(function() ModeInfo.Text = modeDesc[i] end)
end

-- ── Script history ─────────────────────────────────────────────────────────────
local execHistory = {}
local histIdx     = 0

local function pushHistory(code)
    if code == "" or code == execHistory[#execHistory] then return end
    table.insert(execHistory, code)
    if #execHistory > 30 then table.remove(execHistory, 1) end
    histIdx = #execHistory
end

-- ── Code editor ───────────────────────────────────────────────────────────────
local Editor = IN(P1,
    "-- Mode 1: client loadstring  (paste code here)\n"..
    "-- Mode 2: server-side bridge (paste code here)\n"..
    "-- Mode 3: enter asset ID     (e.g. 1234567890)\n"..
    "-- Mode 4: enter raw URL      (https://…)\n"..
    "-- Mode 5: enter file path    (e.g. script.lua)\n",
    UDim2.new(1,0,0,180), UDim2.new(0,0,0,44))

-- Line + char counter
L(P1, "Output", UDim2.new(0,55,0,14), UDim2.new(0,0,0,230), C.TXTS, FN, 11)
local LineCnt = L(P1, "0 lines · 0 chars",
    UDim2.new(0,180,0,14), UDim2.new(1,-182,0,230), C.TXTD, FN, 10, Enum.TextXAlignment.Right)

Editor:GetPropertyChangedSignal("Text"):Connect(function()
    local txt = Editor.Text
    local lines = select(2, txt:gsub("\n", "")) + 1
    LineCnt.Text = lines .. " lines · " .. #txt .. " chars"
end)

-- ── Action row ────────────────────────────────────────────────────────────────
local aRow   = rowBar(P1, 228, 26)
local BExec  = B(aRow,"▶ Run",   UDim2.new(0,88,1,0), nil, C.ACC)
local BClear = B(aRow,"Clear",   UDim2.new(0,64,1,0), nil, C.GREY)
local BCopy  = B(aRow,"Copy",    UDim2.new(0,64,1,0), nil, C.GREY)
local BPrev  = B(aRow,"◀ Prev",  UDim2.new(0,68,1,0), nil, C.GREY)
local BNext  = B(aRow,"Next ▶",  UDim2.new(0,68,1,0), nil, C.GREY)
local BSave  = B(aRow,"Save",    UDim2.new(0,60,1,0), nil, C.GREY)
styleRow({BExec,BClear,BCopy,BPrev,BNext,BSave})
hov(BExec,  C.ACC,  C.ACCHV)
hov(BClear, C.GREY, C.GRYHV)
hov(BCopy,  C.GREY, C.GRYHV)
hov(BPrev,  C.GREY, C.GRYHV)
hov(BNext,  C.GREY, C.GRYHV)
hov(BSave,  C.GREY, C.GRYHV)

-- ── Output console ────────────────────────────────────────────────────────────
local ExOut  = OUT(P1, UDim2.new(1,0,1,-260), UDim2.new(0,0,0,258))
local outLog = {}

local function exOut(msg, isErr)
    local line = ts() .. tostring(msg)
    table.insert(outLog, 1, line)
    if #outLog > 100 then table.remove(outLog) end
    ExOut.TextColor3 = isErr and C.RED or C.GRN
    ExOut.Text = table.concat(outLog, "\n"):sub(1, 2000)
end

-- ── Execute handler ───────────────────────────────────────────────────────────
BExec.MouseButton1Click:Connect(function()
    local code = Editor.Text
    if trim(code) == "" then exOut("Nothing to run.", true); return end
    pushHistory(code)
    flash(BExec, C.ACCHV)

    if curMode == 1 then
        -- Client loadstring
        local ok2, err, stage = runCode(code)
        if not ok2 then
            exOut((stage=="compile" and "Compile error:\n" or "Runtime error:\n")..err, true); return
        end
        exOut("Client exec ✓", false)

    elseif curMode == 2 then
        -- Server-side via bridge
        local ok2, msg2 = runOnServer(code)
        exOut(msg2 or "(no response from bridge)", not ok2)

    elseif curMode == 3 then
        -- require by asset ID
        local id = tonumber(code:match("%d+"))
        if not id then exOut("Enter a valid numeric asset ID.", true); return end
        local ok2, res = pcall(require, id)
        exOut(ok2 and ("require(" .. id .. ") returned: " .. type(res))
            or "require error:\n" .. tostring(res), not ok2)

    elseif curMode == 4 then
        -- URL fetch + execute
        local url = trim(code)
        if url == "" then exOut("Enter a URL.", true); return end
        exOut("Fetching " .. trunc(url, 60) .. "…", false)
        task.spawn(function()
            local ok2, src = pcall(game.HttpGet, game, url, true)
            if not ok2 then exOut("HTTP error:\n" .. tostring(src), true); return end
            local ok3, err, stage = runCode(src)
            if not ok3 then
                exOut((stage=="compile" and "Compile error:\n" or "Runtime error:\n")..err, true); return
            end
            exOut("URL exec ✓  (" .. #src .. " bytes)", false)
        end)

    elseif curMode == 5 then
        -- Local file
        if not readfile then exOut("readfile not available on this executor.", true); return end
        local path = trim(code)
        if path == "" then exOut("Enter a file path.", true); return end
        local ok2, src = pcall(readfile, path)
        if not ok2 then exOut("readfile error:\n" .. tostring(src), true); return end
        local ok3, err, stage = runCode(src)
        if not ok3 then
            exOut((stage=="compile" and "Compile error:\n" or "Runtime error:\n")..err, true); return
        end
        exOut("File exec ✓  (" .. #src .. " bytes, path: " .. path .. ")", false)
    end
end)

BClear.MouseButton1Click:Connect(function()
    Editor.Text = ""; outLog = {}; ExOut.Text = ""
end)

BCopy.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(Editor.Text)
        exOut("Code copied to clipboard ✓", false)
    else
        exOut("setclipboard not available on this executor.", true)
    end
end)

BPrev.MouseButton1Click:Connect(function()
    if #execHistory == 0 then exOut("History is empty.", true); return end
    histIdx = math.max(1, histIdx - 1)
    Editor.Text = execHistory[histIdx]
    exOut("History " .. histIdx .. " / " .. #execHistory, false)
end)

BNext.MouseButton1Click:Connect(function()
    if #execHistory == 0 then exOut("History is empty.", true); return end
    histIdx = math.min(#execHistory, histIdx + 1)
    Editor.Text = execHistory[histIdx]
    exOut("History " .. histIdx .. " / " .. #execHistory, false)
end)

BSave.MouseButton1Click:Connect(function()
    if not writefile then exOut("writefile not available.", true); return end
    local name = "nexus_script_" .. os.time() .. ".lua"
    writefile(name, Editor.Text)
    exOut("Saved → " .. name, false)
end)

setMode(1)
