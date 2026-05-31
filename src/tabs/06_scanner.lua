-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 6 — MALWARE SCANNER
--  Pattern scan · Bridge scan · Script list · Kill specific script
-- ═══════════════════════════════════════════════════════════════════════════════
local P6 = newTab("🔎", "Scanner")
L(P6, "MALWARE & SCRIPT SCANNER", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

local scRow = rowBar(P6, 18, 26)
local BScanRun  = B(scRow, "Scan Game",   UDim2.new(0,100,1,0), nil, C.ACC)
local BScanKill = B(scRow, "Kill All LS", UDim2.new(0,92,1,0),  nil, C.RED)
local BScanList = B(scRow, "List Scripts",UDim2.new(0,106,1,0), nil, C.BLUE)
local BScanBrdg = B(scRow, "Bridge Scan", UDim2.new(0,106,1,0), nil, C.GREY)
local BScanKill1= B(scRow, "Kill Name",   UDim2.new(0,96,1,0),  nil, C.GREY)
for i, b in {BScanRun,BScanKill,BScanList,BScanBrdg,BScanKill1} do
    b.LayoutOrder = i; b.TextSize = 11
end
hov(BScanRun,  C.ACC,  C.ACCHV); hov(BScanKill, C.RED,  C.REDHV)
hov(BScanList, C.BLUE, C.BLHV);  hov(BScanBrdg, C.GREY, C.GRYHV)
hov(BScanKill1,C.GREY, C.GRYHV)

local ScanOut = OUT(P6, UDim2.new(1,0,1,-52), UDim2.new(0,0,0,50))
local function scanOut(msg, ok2) ScanOut.TextColor3 = ok2 and C.GRN or C.RED; ScanOut.Text = ts()..tostring(msg) end

-- Kill-by-name input (inline below buttons)
local KillNameIn = INS(P6, "Script name to kill…", UDim2.new(0.55,0,0,20), UDim2.new(0,0,0,48))

-- ── Signature database ────────────────────────────────────────────────────────
local SIGS = {
    -- HTTP abuse
    {pat="HttpGet.*pastebin",     sev="HIGH",   lbl="Pastebin fetch"},
    {pat="HttpGet.*discord%.gg",  sev="HIGH",   lbl="Discord invite fetch"},
    {pat="HttpGet.*bit%.ly",      sev="MED",    lbl="URL shortener fetch"},
    {pat="request%s*%(%s*{",      sev="MED",    lbl="HTTP request object"},
    {pat="syn%.request",          sev="MED",    lbl="syn.request HTTP call"},
    {pat="http%.request",         sev="MED",    lbl="http.request call"},
    -- Environment manipulation
    {pat="getfenv%(0%)",          sev="HIGH",   lbl="getfenv(0) — env tamper"},
    {pat="getfenv.*setfenv",      sev="HIGH",   lbl="Environment hijack"},
    {pat="setfenv.*getfenv",      sev="HIGH",   lbl="Environment swap"},
    -- Hooking / patching
    {pat="hookfunction",          sev="MED",    lbl="hookfunction detected"},
    {pat="hookmetamethod",        sev="MED",    lbl="hookmetamethod detected"},
    {pat="replaceclosure",        sev="MED",    lbl="replaceclosure"},
    {pat="setreadonly.*false",     sev="MED",    lbl="Metatable unlock"},
    -- Player targeting
    {pat="Players.*:Remove%(",    sev="HIGH",   lbl="Forced player removal"},
    {pat="game%.Players.*Kick",   sev="HIGH",   lbl="Player kick call"},
    -- Crash / exploit
    {pat="while true do",         sev="LOW",    lbl="Infinite loop"},
    {pat="Instance%.new.*%-%-",   sev="LOW",    lbl="Instance spam (commented hint)"},
    {pat="error%(%d%d%d%d%d",    sev="MED",    lbl="Mass error throw"},
    -- Data exfiltration
    {pat="game%.JobId",           sev="LOW",    lbl="JobId access"},
    {pat="Players%.LocalPlayer.*UserId", sev="MED", lbl="UserId exfil attempt"},
    -- Obfuscation tells
    {pat="\\x%x%x\\x%x%x",       sev="LOW",    lbl="Hex-escaped payload"},
    {pat="string%.char%(%d+,%d+", sev="LOW",    lbl="string.char encoded blob"},
    {pat="_[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]", sev="LOW", lbl="Hex variable names"},
    -- Remote abuse
    {pat="FireServer.*%b()",      sev="LOW",    lbl="FireServer call"},
    {pat="InvokeServer.*%b()",    sev="LOW",    lbl="InvokeServer call"},
}

local SEV_COL = {HIGH = C.RED, MED = C.ORAN, LOW = C.YELL}

local function scanScript(scr)
    local src = ""
    pcall(function() if getscriptsource then src = getscriptsource(scr) end end)
    if src == "" then return {} end
    local hits = {}
    for _, sig in SIGS do
        if src:find(sig.pat) then
            hits[#hits+1] = {lbl = sig.lbl, sev = sig.sev}
        end
    end
    return hits
end

BScanRun.MouseButton1Click:Connect(function()
    scanOut("Scanning all scripts…", true)
    task.spawn(function()
        local results  = {}
        local total    = 0
        local flagged  = 0
        local highCnt  = 0

        local function recurse(obj)
            for _, ch in obj:GetChildren() do
                if ch:IsA("LocalScript") or ch:IsA("ModuleScript") or ch:IsA("Script") then
                    total += 1
                    local hits = scanScript(ch)
                    if #hits > 0 then
                        flagged += 1
                        results[#results+1] = "⚠  " .. ch:GetFullName()
                        for _, h in hits do
                            results[#results+1] = "   [" .. h.sev .. "] " .. h.lbl
                            if h.sev == "HIGH" then highCnt += 1 end
                        end
                    end
                end
                recurse(ch)
            end
        end
        recurse(game)

        if #results == 0 then
            scanOut(("Scanned %d scripts — no signatures found ✓"):format(total), true)
        else
            local header = ("Scanned %d scripts | %d flagged | %d HIGH severity hits"):format(
                total, flagged, highCnt)
            scanOut(header .. "\n" .. table.concat(results, "\n"), highCnt == 0)
        end
    end)
end)

BScanKill.MouseButton1Click:Connect(function()
    local ok2, msg2 = killAllScripts()
    scanOut(msg2 or "Bridge error", ok2)
end)

BScanList.MouseButton1Click:Connect(function()
    local lines = {}; local n = 0
    local function recurse(obj)
        for _, ch in obj:GetChildren() do
            if ch:IsA("LocalScript") or ch:IsA("ModuleScript") or ch:IsA("Script") then
                n += 1
                lines[#lines+1] = ("[%s] %s"):format(ch.ClassName, ch:GetFullName())
            end
            recurse(ch)
        end
    end
    recurse(game)
    scanOut(n .. " scripts found:\n" .. table.concat(lines, "\n"), true)
end)

BScanBrdg.MouseButton1Click:Connect(function()
    local ok2, msg2, data = serverScan()
    local lines = {msg2 or ""}
    if data then for _, l in data do lines[#lines+1] = tostring(l) end end
    scanOut(table.concat(lines, "\n"), ok2)
end)

BScanKill1.MouseButton1Click:Connect(function()
    local name = trim(KillNameIn.Text)
    if name == "" then scanOut("Enter a script name.", false); return end
    local ok2, msg2 = killScript(name)
    scanOut(msg2 or "Bridge error", ok2)
end)
