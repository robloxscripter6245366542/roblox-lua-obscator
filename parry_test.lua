-- parry_test.lua
-- Spam-tests every parry method every 0.5s
-- Run in lobby to verify clicks are registering

local UIS   = game:GetService("UserInputService")
local SG    = game:GetService("StarterGui")
local LP    = game:GetService("Players").LocalPlayer
local PGui  = LP:WaitForChild("PlayerGui", 10)
local cam   = workspace.CurrentCamera

local function notify(t,m)
    pcall(function() SG:SetCore("SendNotification",{Title=t,Text=m,Duration=4}) end)
end

-- ── Strategy helpers ────────────────────────────────────────────────────────

local getUV = (type(debug)=="table" and type(debug.getupvalues)=="function" and debug.getupvalues)
           or (type(getupvalues)=="function" and getupvalues)
           or nil

local function upvalueSearch(fn)
    if not getUV or type(fn)~="function" then return nil end
    local ok,uvs = pcall(getUV,fn)
    if not (ok and uvs) then return nil end
    for _,uv in pairs(uvs) do
        if type(uv)=="table" and type(uv.Block)=="function" then return uv.Block end
    end
end

local cachedFn = nil

local function findBlockFn()
    if cachedFn then return cachedFn end

    -- Strategy 1: TouchTapInWorld upvalues
    if type(getconnections)=="function" then
        local ok,conns = pcall(getconnections, UIS.TouchTapInWorld)
        if ok and conns then
            for _,c in ipairs(conns) do
                local fn; pcall(function() fn=c.Function end)
                local b = upvalueSearch(fn)
                if b then print("[TEST] Found via TouchTapInWorld"); cachedFn=b; return b end
            end
        end
    end

    -- Strategy 2: Block button connections
    if type(getconnections)=="function" then
        local btn
        pcall(function()
            btn = PGui:WaitForChild("HUD",1)
                      :WaitForChild("Actions",1)
                      :WaitForChild("MainButtons",1)
                      :WaitForChild("Block",1)
        end)
        if btn then
            for _,ev in ipairs({"Activated","MouseButton1Click","MouseButton1Down","InputBegan"}) do
                local ok,conns = pcall(function() return getconnections(btn[ev]) end)
                if ok and conns then
                    for _,c in ipairs(conns) do
                        local fn; pcall(function() fn=c.Function end)
                        local b = upvalueSearch(fn) or fn
                        if type(b)=="function" then
                            print("[TEST] Found via button "..ev)
                            cachedFn=b; return b
                        end
                    end
                end
            end
        end
    end

    -- Strategy 3: getsenv
    if type(getsenv)=="function" then
        local sc
        pcall(function()
            sc = LP:WaitForChild("PlayerScripts",1)
                   :WaitForChild("Scripts",1)
                   :WaitForChild("SwordController",1)
        end)
        if sc then
            local ok,env = pcall(getsenv,sc)
            if ok and env then
                for _,v in pairs(env) do
                    if type(v)=="table" and type(v.Block)=="function" then
                        print("[TEST] Found via getsenv")
                        cachedFn=v.Block; return v.Block
                    end
                end
            end
        end
    end

    -- Strategy 4: getgc shape scan
    if type(getgc)=="function" then
        local ok,gc = pcall(getgc,false)
        if ok and gc then
            for _,v in ipairs(gc) do
                if type(v)=="table" and type(v.Block)=="function"
                and type(v.ShowShield)=="function" then
                    print("[TEST] Found via getgc")
                    cachedFn=v.Block; return v.Block
                end
            end
        end
    end

    return nil
end

local function findBlockRemote()
    local rs = game:GetService("ReplicatedStorage")
    for _,v in pairs(rs:GetDescendants()) do
        if v:IsA("RemoteFunction") and v.Name=="Block" then return v end
    end
end

local function findBlockBtn()
    local btn
    pcall(function()
        btn = PGui:FindFirstChild("HUD",true)
        btn = btn and btn:FindFirstChild("Actions",true)
        btn = btn and btn:FindFirstChild("MainButtons",true)
        btn = btn and btn:FindFirstChild("Block")
    end)
    if not btn then
        for _,v in pairs(PGui:GetDescendants()) do
            if v.Name=="Block" and (v:IsA("TextButton") or v:IsA("ImageButton")) then
                btn=v; break
            end
        end
    end
    return btn
end

-- ── Spam loop ───────────────────────────────────────────────────────────────

local count = 0
notify("Parry Test","Running — check console for results")

game:GetService("RunService").Heartbeat:Connect(function()
    -- throttle to once every 0.5s
    if (count % 30) ~= 0 then count=count+1; return end
    count = count + 1

    local fired = false

    -- Method A: direct Block fn
    local fn = findBlockFn()
    if type(fn)=="function" then
        local ok,er = pcall(fn)
        print("[TEST] Block() called → "..(ok and "OK" or tostring(er)))
        fired = true
    end

    -- Method B: RemoteFunction
    local remote = findBlockRemote()
    if remote then
        local ok,er = pcall(function() remote:InvokeServer(cam.CFrame.LookVector.Y) end)
        print("[TEST] RemoteFunction:InvokeServer → "..(ok and "OK" or tostring(er)))
        fired = true
    end

    -- Method C: VirtualUser button tap
    local btn = findBlockBtn()
    if btn then
        local pos = btn.AbsolutePosition + btn.AbsoluteSize*0.5
        pcall(function()
            game:GetService("VirtualUser"):Button1Down(pos, cam.CFrame)
            task.wait(0.04)
            game:GetService("VirtualUser"):Button1Up(pos, cam.CFrame)
        end)
        print("[TEST] VirtualUser tap on "..btn:GetFullName())
        fired = true
    end

    if not fired then
        print("[TEST] Nothing found yet — waiting for game to load")
    end
end)
