-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 2 — SERVER
--  Server-side loadstring · URL exec · Require · Player management
-- ═══════════════════════════════════════════════════════════════════════════════
local P2 = newTab("⚙", "Server")

L(P2, "SERVER CONTROL", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

-- ── Code editor ───────────────────────────────────────────────────────────────
local SrvEdit = IN(P2, "-- Code to run server-side via bridge…", UDim2.new(1,0,0,80), UDim2.new(0,0,0,18))

-- ── Action row 1 ──────────────────────────────────────────────────────────────
local sr1 = rowBar(P2, 104, 26)
local BSrvRun  = B(sr1, "▶ Run Server",  UDim2.new(0,116,1,0), nil, C.GRN)
local BSrvURL  = B(sr1, "Run URL",        UDim2.new(0,88,1,0),  nil, C.GREY)
local BSrvReq  = B(sr1, "Require ID",     UDim2.new(0,92,1,0),  nil, C.GREY)
local BSrvPing = B(sr1, "Ping",           UDim2.new(0,60,1,0),  nil, C.ACC)
styleRow({BSrvRun,BSrvURL,BSrvReq,BSrvPing})
hov(BSrvRun, C.GRN, C.GRNHV); hov(BSrvURL, C.GREY, C.GRYHV)
hov(BSrvReq, C.GREY, C.GRYHV); hov(BSrvPing, C.ACC, C.ACCHV)

-- ── Output ────────────────────────────────────────────────────────────────────
local srvOut = statusOut(P2, UDim2.new(1,0,0,50), UDim2.new(0,0,0,134))
local function bOut(act, pay)
    local ok2, msg2, data = callBridge(act, pay)
    local lines = {msg2 or ""}
    if data then for _, l in data do lines[#lines+1] = tostring(l) end end
    srvOut(table.concat(lines, "\n"), ok2)
end

BSrvRun.MouseButton1Click:Connect(function()
    if trim(SrvEdit.Text) == "" then srvOut("No code.", false); return end
    bOut("ls", {code = SrvEdit.Text})
end)
BSrvURL.MouseButton1Click:Connect(function()
    local url = trim(SrvEdit.Text)
    if url == "" then srvOut("Enter URL in editor.", false); return end
    bOut("ls_url", {url = url})
end)
BSrvReq.MouseButton1Click:Connect(function()
    local id = tonumber(SrvEdit.Text:match("%d+"))
    if not id then srvOut("Enter asset ID in editor.", false); return end
    bOut("req", {id = id})
end)
BSrvPing.MouseButton1Click:Connect(function()
    local ok2, msg2 = bridgeStatus()
    srvOut(msg2, ok2)
end)

-- ── Action row 2 — Quick commands ─────────────────────────────────────────────
local sr2 = rowBar(P2, 190, 26)
local BGetPlrs = B(sr2, "Get Players",  UDim2.new(0,100,1,0), nil, C.GREY)
local BGetScr  = B(sr2, "Get Scripts",  UDim2.new(0,100,1,0), nil, C.GREY)
local BKillAll = B(sr2, "Kill Scripts", UDim2.new(0,106,1,0), nil, C.RED)
local BBridge  = B(sr2, "Re-Ping",      UDim2.new(0,80,1,0),  nil, C.GREY)
styleRow({BGetPlrs,BGetScr,BKillAll,BBridge})
hov(BGetPlrs, C.GREY, C.GRYHV); hov(BGetScr,  C.GREY, C.GRYHV)
hov(BKillAll, C.RED,  C.REDHV); hov(BBridge,  C.GREY, C.GRYHV)

BGetPlrs.MouseButton1Click:Connect(function() bOut("getplrs")       end)
BGetScr.MouseButton1Click:Connect(function()  bOut("get_scripts")    end)
BKillAll.MouseButton1Click:Connect(function() bOut("kill_all")       end)
BBridge.MouseButton1Click:Connect(function()
    local alive = pingBridge()
    ODot.BackgroundColor3 = alive and C.GRN or C.RED
    BridgeTxt.Text        = alive and "bridge ✓" or "no bridge"
    BridgeTxt.TextColor3  = alive and C.GRN or C.RED
    srvOut(alive and "Bridge online ✓" or "Bridge offline.", alive)
end)

-- ── Player management panel ───────────────────────────────────────────────────
L(P2, "Players", UDim2.new(0,80,0,14), UDim2.new(0,0,0,222), C.TXTS, FB, 11)
local BRefPlrs = B(P2, "↺ Refresh", UDim2.new(0,88,0,18), UDim2.new(1,-90,0,222), C.GREY)
BRefPlrs.TextSize = 10; hov(BRefPlrs, C.GREY, C.GRYHV)

local PlrScr = SCR(P2, UDim2.new(1,0,1,-244), UDim2.new(0,0,0,242))
listV(PlrScr, 3)

local function refreshPlrs()
    clearLayout(PlrScr)
    for _, plr in Players:GetPlayers() do
        local row = F(PlrScr, UDim2.new(1,-4,0,34), nil, C.PANEL); corner(row,6)
        local isMe = (plr == LP)
        -- online dot
        local d = dot(row, UDim2.new(0,7,0,7), UDim2.new(0,6,0.5,-3),
            plr.Character and C.GRN or C.GREY)
        L(row, plr.DisplayName, UDim2.new(0.5,-24,1,0), UDim2.new(0,18,0,0),
            isMe and C.YELL or C.TXT, isMe and FB or FN, 12)
        L(row, "@" .. plr.Name, UDim2.new(0.3,0,1,0), UDim2.new(0.38,0,0,0), C.TXTS, FN, 10)

        local bKick = B(row,"Kick", UDim2.new(0,42,0,20), UDim2.new(1,-90,0.5,-10), isMe and C.GREY or C.RED)
        local bTp   = B(row,"TP",   UDim2.new(0,36,0,20), UDim2.new(1,-44,0.5,-10), C.BLUE)
        bKick.TextSize = 10; bTp.TextSize = 10
        if isMe then bKick.Text = "You" end
        hov(bTp, C.BLUE, C.BLHV)

        bKick.MouseButton1Click:Connect(function()
            if isMe then srvOut("Can't kick yourself.", false); return end
            bOut("kick", {name = plr.Name, reason = "Kicked by Nexus."})
        end)
        bTp.MouseButton1Click:Connect(function()
            local myChar = LP.Character
            local tChar  = plr.Character
            if not myChar or not tChar then srvOut("No character.", false); return end
            local r1 = myChar:FindFirstChild("HumanoidRootPart")
            local r2 = tChar:FindFirstChild("HumanoidRootPart")
            if r1 and r2 then
                r1.CFrame = r2.CFrame + Vector3.new(2,2,2)
                srvOut("Teleported to " .. plr.Name, true)
            end
        end)
    end
end

BRefPlrs.MouseButton1Click:Connect(refreshPlrs)
Players.PlayerAdded:Connect(refreshPlrs)
Players.PlayerRemoving:Connect(function() task.wait(0.1); refreshPlrs() end)
refreshPlrs()
