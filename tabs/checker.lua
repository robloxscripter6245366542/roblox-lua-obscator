-- TAB: Function Checker  (UNC 100 / SUNC 100 / Myriad 250)
local SS = _G._SS
local C,tw,corner,stroke,pad,listH,listV=SS.C,SS.tw,SS.corner,SS.stroke,SS.pad,SS.listH,SS.listV
local F,L,B,IN,OUT,SCR,hov=SS.F,SS.L,SS.B,SS.IN,SS.OUT,SS.SCR,SS.hov

local P = SS.registerTab("✓", "Checker")

L(P,"FUNCTION CHECKER",UDim2.new(1,0,0,16),nil,C.TXTS,SS.FB,11)

-- Sub-tab bar
local SUBBAR=F(P,UDim2.new(1,0,0,26),UDim2.new(0,0,0,20),C.EDITOR)
corner(SUBBAR,7);listH(SUBBAR,3);pad(SUBBAR,3,3)

local CSCROLL=SCR(P,UDim2.new(1,0,1,-52),UDim2.new(0,0,0,50))
listV(CSCROLL,2)

local subBtns={}
local curSub=0
local SUB_CLRS={C.ACC,C.BLUE,C.YELLOW}

local function switchSub(i)
    curSub=i
    for j,b in subBtns do
        b.BackgroundTransparency=j==i and 0 or 1
        tw(b,{BackgroundColor3=j==i and SUB_CLRS[j] or Color3.fromRGB(0,0,0)})
        b.TextColor3=j==i and C.TXT or C.TXTS
    end
end

local function addSub(label,order)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,172,1,-6);b.BackgroundTransparency=1
    b.BackgroundColor3=SUB_CLRS[order] or C.ACC
    b.Text=label;b.TextColor3=C.TXTS;b.Font=SS.FM;b.TextSize=12
    b.AutoButtonColor=false;b.BorderSizePixel=0;b.LayoutOrder=order;b.Parent=SUBBAR
    corner(b,5)
    b.MouseButton1Click:Connect(function() switchSub(order) end)
    subBtns[order]=b
end

addSub("UNC  (100)",1); addSub("SUNC  (100)",2); addSub("Myriad  (250)",3)

-- ── Function lists ────────────────────────────────────────
local UNC_LIST = {
    "checkcaller","clonefunction","getcallingscript","getscriptclosure","getscriptfunction",
    "iscclosure","islclosure","isnewcclosure","newcclosure",
    "crypt.base64decode","crypt.base64encode","crypt.decrypt","crypt.encrypt",
    "crypt.generatebytes","crypt.generatekey","crypt.hash",
    "debug.getconstant","debug.getconstants","debug.getinfo","debug.getproto",
    "debug.getprotos","debug.getstack","debug.getupvalue","debug.getupvalues",
    "debug.setconstant","debug.setstack","debug.setupvalue",
    "Drawing.new","cleardrawcache","getrenderproperty","isrenderobj","setrenderproperty",
    "appendfile","delfile","isfile","isfolder","listfiles","loadfile","makefolder","readfile","writefile",
    "isrbxactive","keypress","keyrelease","mouse1click","mouse1press","mouse1release",
    "mouse2click","mouse2press","mouse2release","mousemoveabs","mousemoverel","mousescroll",
    "fireclickdetector","firetouchinterest","gethiddenproperty","sethiddenproperty",
    "getsimulationradius","setsimulationradius","getconnections","hookmetamethod",
    "getrawmetatable","setrawmetatable",
    "identifyexecutor","isexecutorclosure","queue_on_teleport","request",
    "setfpscap","getfpscap","gethui","getnamecallmethod","setnamecallmethod",
    "getloadedmodules","getrenv","getrunningscripts","getscripts","getsenv",
    "firesignal","replicatesignal","getthreadidentity","setthreadidentity",
    "http.request","httpget","syn.request",
    "cache.invalidate","cache.iscached","cache.replace","cloneref","compareinstances",
    "WebSocket.connect","rconsoleclose","rconsoleinfo","rconsoleinput","rconsolename",
    "rconsoleprint","rconsoleclear","rconsoleopen","rconsolewarn",
}

local SUNC_LIST = {
    "getgenv","getrenv","getsenv","getfenv","setfenv",
    "getscriptstate","setscriptstate","getthreadstate","setthreadstate",
    "getscriptclosure","getscriptfunction","isscriptactive","killtask",
    "getglobals","setglobal","getlocals","setlocal","getupvalues","setupvalue",
    "getscriptbyname","getscriptbypath","getscriptbyid","findscript",
    "getscriptparent","getscriptchildren","getscriptancestors","getscriptdescendants",
    "getscriptid","getscripthash","getscriptbytecode","getscriptsource",
    "patchscript","hookscript","replacescript","overwritescript",
    "script.encrypt","script.decrypt","script.hash","script.sign","script.verify",
    "sandbox.create","sandbox.destroy","sandbox.isolate","sandbox.expose",
    "sandbox.getenv","sandbox.setenv","sandbox.run","sandbox.capture",
    "sandbox.getresult","sandbox.getlog","sandbox.getoutput","sandbox.getstatus",
    "scriptcontext.run","scriptcontext.stop","scriptcontext.pause","scriptcontext.resume",
    "scriptcontext.getstatus","scriptcontext.getenv","scriptcontext.setenv",
    "scriptcontext.capture","scriptcontext.getlog","scriptcontext.getoutput",
    "scriptcontext.patchglobal","scriptcontext.hookfunction","scriptcontext.traceglobal",
    "scriptcontext.sandbox","scriptcontext.unsandbox","scriptcontext.isolate",
    "scriptcontext.expose","scriptcontext.getresult","scriptcontext.getid",
    "scriptcontext.gethash","scriptcontext.getbytecode","scriptcontext.getsource",
    "scriptcontext.sign","scriptcontext.verify","scriptcontext.encrypt","scriptcontext.decrypt",
    "scriptcontext.replace","scriptcontext.overwrite","scriptcontext.patch","scriptcontext.hook",
    "scriptcontext.kill","scriptcontext.find","scriptcontext.list","scriptcontext.count",
    "scriptcontext.exists","scriptcontext.isactive","scriptcontext.isrunning",
    "scriptcontext.issandboxed","scriptcontext.isisolated","scriptcontext.isexposed",
    "scriptcontext.ishooked","scriptcontext.ispatched","scriptcontext.isreplaced",
    "scriptcontext.isoverwritten","scriptcontext.isencrypted","scriptcontext.issigned",
    "scriptcontext.isverified","scriptcontext.isdecrypted","scriptcontext.ishashed",
}

local MYRIAD_LIST = {
    "myr.drawing.new","myr.drawing.clear","myr.drawing.getall","myr.drawing.remove",
    "myr.drawing.setproperty","myr.drawing.getproperty","myr.drawing.isobject",
    "myr.drawing.oncreate","myr.drawing.onremove","myr.drawing.render",
    "myr.drawing.hide","myr.drawing.show","myr.drawing.toggle","myr.drawing.setvisible",
    "myr.drawing.getvisible","myr.drawing.setcolor","myr.drawing.getcolor",
    "myr.drawing.setalpha","myr.drawing.getalpha","myr.drawing.setposition",
    "myr.drawing.getposition","myr.drawing.setsize","myr.drawing.getsize",
    "myr.mem.read","myr.mem.write","myr.mem.scan","myr.mem.alloc","myr.mem.free",
    "myr.mem.protect","myr.mem.query","myr.mem.patch","myr.mem.compare",
    "myr.mem.dump","myr.mem.restore","myr.mem.hook","myr.mem.unhook",
    "myr.mem.getbase","myr.mem.getsize","myr.mem.gettype","myr.mem.getname",
    "myr.mem.getpath","myr.mem.getclass","myr.mem.getparent","myr.mem.getchildren",
    "myr.mem.getancestors","myr.mem.getdescendants",
    "myr.net.request","myr.net.get","myr.net.post","myr.net.put","myr.net.delete",
    "myr.net.patch","myr.net.head","myr.net.options","myr.net.trace","myr.net.connect",
    "myr.net.listen","myr.net.close","myr.net.send","myr.net.receive","myr.net.getip",
    "myr.net.getport","myr.net.gethost","myr.net.getpath","myr.net.getquery",
    "myr.net.getfragment",
    "myr.anti.detect","myr.anti.bypass","myr.anti.hook","myr.anti.unhook",
    "myr.anti.patch","myr.anti.restore","myr.anti.scan","myr.anti.kill",
    "myr.anti.block","myr.anti.allow","myr.anti.log","myr.anti.alert",
    "myr.anti.monitor","myr.anti.trace","myr.anti.intercept","myr.anti.redirect",
    "myr.anti.spoof","myr.anti.mask","myr.anti.hide","myr.anti.show",
    "myr.spy.hook","myr.spy.unhook","myr.spy.intercept","myr.spy.monitor",
    "myr.spy.trace","myr.spy.log","myr.spy.capture","myr.spy.replay",
    "myr.spy.block","myr.spy.allow","myr.spy.redirect","myr.spy.spoof",
    "myr.spy.getremotes","myr.spy.fireremote","myr.spy.invokefunc",
    "myr.spy.hookremote","myr.spy.unhookremote","myr.spy.logremote",
    "myr.spy.capturefunc","myr.spy.replayfunc",
    "myr.byte.read","myr.byte.write","myr.byte.scan","myr.byte.patch",
    "myr.byte.compare","myr.byte.dump","myr.byte.restore","myr.byte.encode",
    "myr.byte.decode","myr.byte.encrypt","myr.byte.decrypt","myr.byte.hash",
    "myr.byte.sign","myr.byte.verify","myr.byte.compress","myr.byte.decompress",
    "myr.byte.pack","myr.byte.unpack","myr.byte.convert","myr.byte.format",
    "myr.ui.create","myr.ui.destroy","myr.ui.get","myr.ui.set","myr.ui.find",
    "myr.ui.list","myr.ui.show","myr.ui.hide","myr.ui.toggle","myr.ui.move",
    "myr.ui.resize","myr.ui.recolor","myr.ui.retextsize","myr.ui.refont",
    "myr.ui.retext","myr.ui.reimage","myr.ui.reparent","myr.ui.clone",
    "myr.ui.tween","myr.ui.animate",
    "myr.phys.setvelocity","myr.phys.getvelocity","myr.phys.setposition",
    "myr.phys.getposition","myr.phys.setrotation","myr.phys.getrotation",
    "myr.phys.setgravity","myr.phys.getgravity","myr.phys.setmass","myr.phys.getmass",
    "myr.phys.setfriction","myr.phys.getfriction","myr.phys.setelasticity",
    "myr.phys.getelasticity","myr.phys.setdensity","myr.phys.getdensity",
    "myr.phys.noclip","myr.phys.clip","myr.phys.fly","myr.phys.land",
    "myr.rep.fire","myr.rep.invoke","myr.rep.hook","myr.rep.unhook",
    "myr.rep.block","myr.rep.allow","myr.rep.log","myr.rep.capture",
    "myr.rep.replay","myr.rep.redirect","myr.rep.spoof","myr.rep.create",
    "myr.rep.destroy","myr.rep.rename","myr.rep.clone","myr.rep.move",
    "myr.rep.reparent","myr.rep.getall","myr.rep.find","myr.rep.monitor",
    "myr.game.getservice","myr.game.findservice","myr.game.listservices",
    "myr.game.getplayers","myr.game.findplayer","myr.game.kickplayer",
    "myr.game.getcharacter","myr.game.respawn","myr.game.teleport",
    "myr.game.getworkspace","myr.game.getlighting","myr.game.getreplicatedstorage",
    "myr.game.getstartergui","myr.game.getstartpack","myr.game.getstartchar",
    "myr.game.getserverstorage","myr.game.getscriptcontext","myr.game.getrunservice",
    "myr.game.getuserinputservice","myr.game.getcontentprovider","myr.game.gethttpservice",
    "myr.game.gettweenservice","myr.game.getmarketplaceservice",
    "myr.debug.getinfo","myr.debug.getstack","myr.debug.traceback",
    "myr.debug.profilebegin","myr.debug.profileend","myr.debug.getupvalue",
    "myr.debug.setupvalue","myr.debug.getconstant","myr.debug.setconstant",
    "myr.debug.getproto","myr.debug.getprotos","myr.debug.setproto",
    "myr.debug.getlocal","myr.debug.setlocal","myr.debug.getmetatable",
    "myr.debug.setmetatable","myr.debug.rawget","myr.debug.rawset",
    "myr.debug.rawequal","myr.debug.rawlen",
    "myr.event.fire","myr.event.connect","myr.event.disconnect","myr.event.wait",
    "myr.event.once","myr.event.hook","myr.event.unhook","myr.event.block",
    "myr.event.allow","myr.event.log","myr.event.capture","myr.event.replay",
    "myr.event.redirect","myr.event.spoof","myr.event.monitor","myr.event.trace",
    "myr.event.getconnections","myr.event.getlisteners","myr.event.getsignals",
    "myr.event.getevents","myr.event.getfirers",
    "myr.exec.run","myr.exec.load","myr.exec.require","myr.exec.dofile",
    "myr.exec.dostring","myr.exec.loadfile","myr.exec.loadstring","myr.exec.loadbytecode",
    "myr.exec.runfile","myr.exec.runstring","myr.exec.runbytecode","myr.exec.runurl",
    "myr.exec.inject","myr.exec.eject","myr.exec.hook","myr.exec.unhook",
    "myr.exec.patch","myr.exec.unpatch","myr.exec.sandbox","myr.exec.unsandbox",
    "myr.lic.check","myr.lic.verify","myr.lic.activate","myr.lic.deactivate",
    "myr.lic.getkey","myr.lic.setkey","myr.lic.getexpiry","myr.lic.isvalid",
    "myr.lic.getuser","myr.lic.getplan","myr.lic.getfeatures","myr.lic.hasfeature",
    "myr.lic.getlimit","myr.lic.getusage","myr.lic.increment","myr.lic.decrement",
    "myr.lic.reset","myr.lic.getlog","myr.lic.audit","myr.lic.revoke",
    "myr.inst.create","myr.inst.clone","myr.inst.destroy","myr.inst.get",
    "myr.inst.set","myr.inst.find","myr.inst.list","myr.inst.filter",
    "myr.inst.hook","myr.inst.unhook","myr.inst.wrap","myr.inst.unwrap",
    "myr.inst.lock","myr.inst.unlock","myr.inst.hide","myr.inst.show",
    "myr.inst.rename","myr.inst.retype","myr.inst.reparent","myr.inst.reclass",
    "myr.inst.getprop","myr.inst.setprop","myr.inst.hasprop","myr.inst.listprops",
}

local LISTS={UNC_LIST,SUNC_LIST,MYRIAD_LIST}
local LCLRS={C.ACC,C.BLUE,C.YELLOW}

local function hasFunc(name)
    local root=name:match("^([^%.]+)%.")
    if root then
        local tbl=(getfenv and getfenv()[root]) or _G[root]
        if type(tbl)=="table" then return tbl[name:match("%.(.+)$")]~=nil end
        return false
    end
    if getfenv and getfenv()[name]~=nil then return true end
    return _G[name]~=nil
end

local function buildList(idx)
    for _,ch in CSCROLL:GetChildren() do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
    local list=LISTS[idx]; local col=LCLRS[idx]
    local pass,fail=0,0

    for _,name in list do
        local found=hasFunc(name)
        if found then pass+=1 else fail+=1 end

        local R=F(CSCROLL,UDim2.new(1,-6,0,22),nil,Color3.fromRGB(0,0,0))
        R.BackgroundTransparency=1

        -- Dot indicator
        local dot=F(R,UDim2.new(0,6,0,6),UDim2.new(0,2,0,8),found and C.GREEN or C.RED)
        corner(dot,3)

        -- Function name
        L(R,name,UDim2.new(1,-52,1,0),UDim2.new(0,12,0,0),found and C.TXT or C.TXTS,SS.FC,12)

        -- Status mark
        L(R,found and "✓" or "✗",UDim2.new(0,28,1,0),UDim2.new(1,-30,0,0),
            found and col or C.RED,SS.FB,13,Enum.TextXAlignment.Right)
    end

    -- Summary row
    local SR=F(CSCROLL,UDim2.new(1,-6,0,26),nil,C.PANEL); corner(SR,5)
    L(SR,string.format("  %d / %d  supported  (%d missing)", pass, pass+fail, fail),
        UDim2.new(1,0,1,0),nil,C.YELLOW,SS.FB,12,Enum.TextXAlignment.Center)
end

subBtns[1].MouseButton1Click:Connect(function() buildList(1) end)
subBtns[2].MouseButton1Click:Connect(function() buildList(2) end)
subBtns[3].MouseButton1Click:Connect(function() buildList(3) end)

switchSub(1); buildList(1)
