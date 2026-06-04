-- simple_parry.lua — taps Block button every 150ms, no complexity
print("[SimpleParry] Loading...")

local Players = game:GetService("Players")
local RS      = game:GetService("RunService")
local SG      = game:GetService("StarterGui")
local cam     = workspace.CurrentCamera
local LP      = Players.LocalPlayer
local PGui    = LP:WaitForChild("PlayerGui", 10)
local VU      = game:GetService("VirtualUser")

pcall(function()
    SG:SetCore("SendNotification",{Title="Simple Parry",Text="Active — tapping Block every 150ms",Duration=4})
end)
print("[SimpleParry] Running")

-- getupvalues helper
local getUV = (type(debug)=="table" and type(debug.getupvalues)=="function" and debug.getupvalues)
           or (type(getupvalues)=="function" and getupvalues) or nil

-- Cache
local blockFn     = nil
local blockRemote = nil
local blockBtn    = nil

-- Find Block button in HUD
local function findBtn()
    if blockBtn and blockBtn.Parent then return blockBtn end
    for _,v in pairs(PGui:GetDescendants()) do
        if v.Name=="Block" and (v:IsA("GuiButton") or v:IsA("TextButton") or v:IsA("ImageButton")) then
            blockBtn = v
            print("[SimpleParry] Block button found: "..v:GetFullName())
            pcall(function() SG:SetCore("SendNotification",{Title="Found",Text="Block button: "..v.Name,Duration=3}) end)
            return v
        end
    end
end

-- Find Block remote
local function findRemote()
    if blockRemote and blockRemote.Parent then return blockRemote end
    for _,v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if v:IsA("RemoteFunction") and v.Name=="Block" then
            blockRemote = v
            print("[SimpleParry] Block remote found: "..v:GetFullName())
            return v
        end
    end
end

-- Find Block fn via all strategies
local function upSearch(fn)
    if not getUV or type(fn)~="function" then return nil end
    local ok,uvs = pcall(getUV,fn)
    if not ok then return nil end
    for _,uv in pairs(uvs or {}) do
        if type(uv)=="table" and type(uv.Block)=="function" then return uv.Block end
    end
end

local function findBlockFn()
    if blockFn then return blockFn end
    -- getconnections on TouchTapInWorld
    if type(getconnections)=="function" then
        local ok,conns=pcall(getconnections, game:GetService("UserInputService").TouchTapInWorld)
        if ok and conns then
            for _,c in ipairs(conns) do
                local fn; pcall(function() fn=c.Function end)
                local b=upSearch(fn)
                if b then blockFn=b; print("[SimpleParry] BlockFn via TTI"); return b end
            end
        end
        -- getconnections on button
        local btn=findBtn()
        if btn then
            for _,ev in ipairs({"Activated","MouseButton1Click","MouseButton1Down"}) do
                local ok2,conns2=pcall(function() return getconnections(btn[ev]) end)
                if ok2 and conns2 then
                    for _,c in ipairs(conns2) do
                        local fn; pcall(function() fn=c.Function end)
                        local b=upSearch(fn) or (type(fn)=="function" and fn or nil)
                        if b then blockFn=b; print("[SimpleParry] BlockFn via btn "..ev); return b end
                    end
                end
            end
        end
    end
    -- getgc scan
    if type(getgc)=="function" then
        local ok,gc=pcall(getgc,false)
        if ok and gc then
            for _,v in ipairs(gc) do
                if type(v)=="table" and type(v.Block)=="function" and type(v.ShowShield)=="function" then
                    blockFn=v.Block; print("[SimpleParry] BlockFn via getgc"); return v.Block
                end
            end
        end
    end
    return nil
end

-- ── Main: fire all methods every 150ms ───────────────────────────────────
local lastFire = 0
RS.Heartbeat:Connect(function()
    local now = tick()
    if (now - lastFire) < 0.15 then return end
    lastFire = now

    -- 1. Real Block() function
    pcall(function()
        local fn = findBlockFn()
        if type(fn)=="function" then fn() end
    end)

    -- 2. RemoteFunction
    pcall(function()
        local r = findRemote()
        if r then r:InvokeServer(0) end
    end)

    -- 3. VirtualUser tap on Block button
    pcall(function()
        local btn = findBtn(); if not btn then return end
        local pos = btn.AbsolutePosition + btn.AbsoluteSize * 0.5
        VU:Button1Down(pos, cam.CFrame)
        task.wait(0.04)
        VU:Button1Up(pos, cam.CFrame)
    end)
end)

-- Report what was found after 3s
task.delay(3, function()
    local found = {}
    if findBlockFn()  then table.insert(found,"BlockFn") end
    if findRemote()   then table.insert(found,"Remote") end
    if findBtn()      then table.insert(found,"Button") end
    local msg = #found>0 and "Found: "..table.concat(found,"+") or "Nothing found yet — join a round"
    pcall(function() SG:SetCore("SendNotification",{Title="Simple Parry",Text=msg,Duration=5}) end)
    print("[SimpleParry] Status: "..msg)
end)
