local SS = _G._SS
local C  = SS.C
local Frm,Lbl,Btn,Inp,Con,Scr,hov,tw = SS.Frm,SS.Lbl,SS.Btn,SS.Inp,SS.Con,SS.Scr,SS.hov,SS.tw
local corner,stroke,listH,listV,rowBar = SS.corner,SS.stroke,SS.listH,SS.listV,SS.rowBar
local FB,FN = SS.FB,SS.FN

local P = SS.newTab("⛓","Sandbox")

Lbl(P, "SANDBOX BYPASS", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

local SBOut = Con(P, UDim2.new(1,0,0,56), UDim2.new(0,0,1,-58))
local function sbOut(msg, ok2)
    SBOut.TextColor3 = ok2 and C.GREEN or C.RED; SBOut.Text = tostring(msg)
end

local SBScr = Scr(P, UDim2.new(1,0,1,-116), UDim2.new(0,0,0,20))
listV(SBScr, 5)

local function utilRow(title, desc, btnTxt, btnCol, action)
    local Row = Frm(SBScr, UDim2.new(1,-4,0,50), nil, C.PANEL)
    corner(Row, 7); stroke(Row, Color3.fromRGB(35,35,52), 1)
    Lbl(Row, title, UDim2.new(1,-108,0,18), UDim2.new(0,8,0,5),  C.TXT,  FB, 13)
    Lbl(Row, desc,  UDim2.new(1,-108,0,16), UDim2.new(0,8,0,25), C.TXTS, FN, 11)
    local bc = btnCol or C.ACC
    local hv = Color3.fromRGB(
        math.min(255, bc.R*255+28),
        math.min(255, bc.G*255+28),
        math.min(255, bc.B*255+28))
    local btn = Btn(Row, btnTxt, UDim2.new(0,88,0,26), UDim2.new(1,-96,0.5,-13), bc)
    hov(btn, bc, hv)
    btn.MouseButton1Click:Connect(function()
        local ok2, res = pcall(action)
        sbOut(res or (ok2 and "✓ Done." or "✗ Failed."), ok2)
    end)
end

utilRow("Elevate Thread Identity", "setthreadidentity(8) — max script context", "Elevate", C.ACC, function()
    local fn = setthreadidentity or (syn and syn.set_thread_identity)
    if not fn then return "✗ setthreadidentity not available." end
    fn(8)
    local gid = getthreadidentity or (syn and syn.get_thread_identity)
    return "✓ Identity=8" .. (gid and " (confirmed "..tostring(gid())..")" or "")
end)

utilRow("Unlock game metatable", "setreadonly(getrawmetatable(game),false)", "Unlock", C.BLUE, function()
    if not getrawmetatable then return "✗ getrawmetatable missing." end
    if not setreadonly     then return "✗ setreadonly missing." end
    setreadonly(getrawmetatable(game), false)
    return "✓ game metatable is writable."
end)

utilRow("Hook __namecall (remote spy)", "Logs FireServer/InvokeServer calls to console", "Hook", C.ORAN, function()
    if not hookmetamethod    then return "✗ hookmetamethod missing." end
    if not getnamecallmethod then return "✗ getnamecallmethod missing." end
    local old2
    old2 = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if m == "FireServer" or m == "InvokeServer" then
            warn("[SS spy] "..tostring(self)..":"..m)
        end
        return old2(self, ...)
    end)
    return "✓ __namecall hooked — remotes logged to console."
end)

utilRow("Open getgenv()", "Access the shared executor global env", "Open", C.GREEN, function()
    if not getgenv then return "✗ getgenv not available." end
    local env = getgenv(); local n = 0; for _ in pairs(env) do n += 1 end
    return "✓ getgenv() ok — "..n.." entries."
end)

utilRow("Open getrenv()", "Access the real Roblox game environment", "Open", C.PURP, function()
    if not getrenv then return "✗ getrenv not available." end
    getrenv(); return "✓ getrenv() ok."
end)

utilRow("Bypass metatable lock", "Strips __index/__newindex guards from game", "Bypass", C.RED, function()
    if not getrawmetatable or not setreadonly then return "✗ Missing functions." end
    local mt = getrawmetatable(game); setreadonly(mt, false)
    return "✓ Metatable lock removed."
end)

-- Custom snippet
local SnipBox  = Inp(SBScr, "-- Custom bypass snippet...", UDim2.new(1,-4,0,60))
local sRow3    = Frm(P, UDim2.new(1,0,0,26), UDim2.new(0,0,1,-60), Color3.fromRGB(0,0,0))
sRow3.BackgroundTransparency = 1; listH(sRow3, 4)
local BSnip    = Btn(sRow3, "▶ Run Snippet", UDim2.new(0,130,1,0), nil, C.ACC)
hov(BSnip, C.ACC, C.ACCHV)
BSnip.MouseButton1Click:Connect(function()
    local code = SnipBox.Text
    if code == "" then sbOut("Enter a snippet.", false); return end
    local ld = loadstring or load
    local fn, ce = ld(code)
    if not fn then sbOut("Compile error:\n"..tostring(ce), false); return end
    local ok2, re = pcall(fn)
    sbOut(ok2 and "✓ Snippet OK." or "✗ "..tostring(re), ok2)
end)

-- Capability summary on load
task.spawn(function()
    local caps = {
        {"setthreadidentity", setthreadidentity},
        {"setreadonly",       setreadonly},
        {"getrawmetatable",   getrawmetatable},
        {"hookmetamethod",    hookmetamethod},
        {"getgenv",           getgenv},
        {"getrenv",           getrenv},
        {"getnamecallmethod", getnamecallmethod},
    }
    local have, miss = {}, {}
    for _,c in caps do (c[2] and have or miss)[#(c[2] and have or miss)+1] = c[1] end
    sbOut(("Executor has %d/%d bypass functions.\nPresent: %s%s"):format(
        #have, #caps, table.concat(have, ", "),
        #miss>0 and ("\nMissing: "..table.concat(miss, ", ")) or ""), #miss==0)
end)
