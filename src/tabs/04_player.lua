-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 4 — PLAYER TOOLS
--  WalkSpeed · JumpPower · Health · God Mode · Noclip · Freeze
--  Infinite Jump · Fly · Speed Presets · Teleport · Position
-- ═══════════════════════════════════════════════════════════════════════════════
local P4 = newTab("👤", "Player")
L(P4, "PLAYER & CHARACTER TOOLS", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

local plrOut = statusOut(P4, UDim2.new(1,0,0,38), UDim2.new(0,0,1,-40))

-- ── Stats row ─────────────────────────────────────────────────────────────────
local statsF = F(P4, UDim2.new(1,0,0,60), UDim2.new(0,0,0,20), C.PANEL); corner(statsF,7)

L(statsF, "WalkSpeed",  UDim2.new(0,78,0,16), UDim2.new(0,6,0,4),   C.TXTS, FN, 11)
L(statsF, "JumpPower",  UDim2.new(0,78,0,16), UDim2.new(0,174,0,4), C.TXTS, FN, 11)
L(statsF, "Health",     UDim2.new(0,55,0,16), UDim2.new(0,342,0,4), C.TXTS, FN, 11)
L(statsF, "MaxHealth",  UDim2.new(0,75,0,16), UDim2.new(0,456,0,4), C.TXTS, FN, 11)

local WalkIn = INS(statsF, "16",    UDim2.new(0,72,0,22), UDim2.new(0,88,0,2))
local JumpIn = INS(statsF, "50",    UDim2.new(0,72,0,22), UDim2.new(0,256,0,2))
local HpIn   = INS(statsF, "100",   UDim2.new(0,56,0,22), UDim2.new(0,400,0,2))
local MxIn   = INS(statsF, "100",   UDim2.new(0,56,0,22), UDim2.new(0,536,0,2))

local BApply = B(statsF, "Apply", UDim2.new(0,52,0,22), UDim2.new(1,-56,0.5,-11), C.GRN)
BApply.TextSize = 11; hov(BApply, C.GRN, C.GRNHV)
BApply.MouseButton1Click:Connect(function()
    local hum = getHum(); if not hum then plrOut("No Humanoid.", false); return end
    local ws = tonumber(WalkIn.Text); if ws then hum.WalkSpeed = ws end
    local jp = tonumber(JumpIn.Text); if jp then hum.JumpPower = jp end
    local mx = tonumber(MxIn.Text);   if mx then hum.MaxHealth = mx end
    local hp = tonumber(HpIn.Text);   if hp then hum.Health = hp end
    plrOut(("WalkSpeed=%.0f  JumpPower=%.0f  HP=%.0f/%.0f"):format(
        hum.WalkSpeed, hum.JumpPower, hum.Health, hum.MaxHealth), true)
end)

-- ── Toggle buttons ────────────────────────────────────────────────────────────
local tRow = rowBar(P4, 86, 26)
local BRespawn = B(tRow, "Respawn",  UDim2.new(0,84,1,0), nil, C.BLUE)
local BGod     = B(tRow, "GodMode",  UDim2.new(0,80,1,0), nil, C.GREY)
local BInfJump = B(tRow, "∞ Jump",  UDim2.new(0,72,1,0), nil, C.GREY)
local BNoclip  = B(tRow, "Noclip",   UDim2.new(0,68,1,0), nil, C.GREY)
local BFreeze  = B(tRow, "Freeze",   UDim2.new(0,68,1,0), nil, C.GREY)
local BFly     = B(tRow, "Fly",      UDim2.new(0,58,1,0), nil, C.GREY)
styleRow({BRespawn,BGod,BInfJump,BNoclip,BFreeze,BFly})
hov(BRespawn, C.BLUE, C.BLHV)
for _, b in {BGod,BInfJump,BNoclip,BFreeze,BFly} do hov(b, C.GREY, C.GRYHV) end

-- Active toggle states
local godOn, jumpOn, noclipOn, freezeOn, flyOn = false, false, false, false, false
local godConn, jumpConn, ncConn, flyConn, flyBp

BRespawn.MouseButton1Click:Connect(function()
    local hum = getHum()
    if hum then hum.Health = 0; plrOut("Respawning…", true)
    else plrOut("No character.", false) end
end)

BGod.MouseButton1Click:Connect(function()
    godOn = not godOn
    tw(BGod, {BackgroundColor3 = godOn and C.GRN or C.GREY})
    BGod.Text = godOn and "✓ God" or "GodMode"
    if godConn then godConn:Disconnect(); godConn = nil end
    if godOn then
        godConn = RUN.Heartbeat:Connect(function()
            local hum = getHum(); if hum then hum.Health = hum.MaxHealth end
        end)
    end
    plrOut("God Mode " .. (godOn and "ON" or "OFF"), godOn)
end)

BInfJump.MouseButton1Click:Connect(function()
    jumpOn = not jumpOn
    tw(BInfJump, {BackgroundColor3 = jumpOn and C.GRN or C.GREY})
    BInfJump.Text = jumpOn and "✓ ∞J" or "∞ Jump"
    if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
    if jumpOn then
        jumpConn = UIS.JumpRequest:Connect(function()
            local hum = getHum()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
    plrOut("Infinite Jump " .. (jumpOn and "ON" or "OFF"), jumpOn)
end)

BNoclip.MouseButton1Click:Connect(function()
    noclipOn = not noclipOn
    tw(BNoclip, {BackgroundColor3 = noclipOn and C.GRN or C.GREY})
    BNoclip.Text = noclipOn and "✓ NC" or "Noclip"
    if ncConn then ncConn:Disconnect(); ncConn = nil end
    if noclipOn then
        ncConn = RUN.Stepped:Connect(function()
            local char = getChar(); if not char then return end
            for _, p in char:GetDescendants() do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    end
    plrOut("Noclip " .. (noclipOn and "ON" or "OFF"), noclipOn)
end)

BFreeze.MouseButton1Click:Connect(function()
    freezeOn = not freezeOn
    tw(BFreeze, {BackgroundColor3 = freezeOn and C.GRN or C.GREY})
    BFreeze.Text = freezeOn and "✓ Frz" or "Freeze"
    local root = getRoot()
    if root then root.Anchored = freezeOn end
    plrOut("Freeze " .. (freezeOn and "ON" or "OFF"), freezeOn)
end)

BFly.MouseButton1Click:Connect(function()
    flyOn = not flyOn
    tw(BFly, {BackgroundColor3 = flyOn and C.GRN or C.GREY})
    BFly.Text = flyOn and "✓ Fly" or "Fly"
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBp then flyBp:Destroy(); flyBp = nil end
    if flyOn then
        local root = getRoot()
        if not root then plrOut("No character for fly.", false); flyOn=false; return end
        flyBp = Instance.new("BodyVelocity")
        flyBp.Velocity = Vector3.new(0,0,0); flyBp.MaxForce = Vector3.new(1e9,1e9,1e9)
        flyBp.Parent = root
        flyConn = RUN.Heartbeat:Connect(function()
            if not flyOn or not flyBp then return end
            local cam = WS.CurrentCamera
            local speed = tonumber(WalkIn.Text) or 40
            local mv = Vector3.new(0,0,0)
            if UIS:IsKeyDown(Enum.KeyCode.W) then mv += cam.CFrame.LookVector * speed end
            if UIS:IsKeyDown(Enum.KeyCode.S) then mv -= cam.CFrame.LookVector * speed end
            if UIS:IsKeyDown(Enum.KeyCode.A) then mv -= cam.CFrame.RightVector * speed end
            if UIS:IsKeyDown(Enum.KeyCode.D) then mv += cam.CFrame.RightVector * speed end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then mv += Vector3.new(0, speed, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then mv -= Vector3.new(0, speed, 0) end
            flyBp.Velocity = mv
        end)
    end
    plrOut("Fly " .. (flyOn and "ON (WASD + Space/Shift)" or "OFF"), flyOn)
end)

-- ── Speed presets ─────────────────────────────────────────────────────────────
local spRow = rowBar(P4, 118, 24)
local presets = {{"Walk",16},{"Run",32},{"Sprint",60},{"Fly",80},{"Hyper",200},{"Ultra",500}}
for i, p in presets do
    local b = B(spRow, p[1], UDim2.new(0,76,1,0), nil, C.GRYDK)
    b.LayoutOrder = i; b.TextSize = 10; hov(b, C.GRYDK, C.GREY)
    local spd = p[2]
    b.MouseButton1Click:Connect(function()
        WalkIn.Text = tostring(spd)
        local hum = getHum()
        if hum then hum.WalkSpeed = spd; plrOut("Speed → " .. spd, true)
        else plrOut("No character.", false) end
    end)
end

-- ── Teleport ──────────────────────────────────────────────────────────────────
L(P4, "Teleport XYZ:", UDim2.new(0,100,0,14), UDim2.new(0,0,0,150), C.TXTS, FN, 11)
local txIn = INS(P4, "X", UDim2.new(0,90,0,24), UDim2.new(0,0,0,166))
local tyIn = INS(P4, "Y", UDim2.new(0,90,0,24), UDim2.new(0,94,0,166))
local tzIn = INS(P4, "Z", UDim2.new(0,90,0,24), UDim2.new(0,188,0,166))
local BTp  = B(P4, "Teleport", UDim2.new(0,100,0,24), UDim2.new(0,282,0,166), C.BLUE)
local BGetPos = B(P4, "Get Pos", UDim2.new(0,88,0,24), UDim2.new(0,386,0,166), C.GREY)
BTp.TextSize = 11; BGetPos.TextSize = 11
hov(BTp, C.BLUE, C.BLHV); hov(BGetPos, C.GREY, C.GRYHV)

BTp.MouseButton1Click:Connect(function()
    local x,y,z = tonumber(txIn.Text), tonumber(tyIn.Text), tonumber(tzIn.Text)
    if not (x and y and z) then plrOut("Enter valid X Y Z.", false); return end
    local root = getRoot()
    if not root then plrOut("No character.", false); return end
    root.CFrame = CFrame.new(x, y, z)
    plrOut(("Teleported → %.1f, %.1f, %.1f"):format(x, y, z), true)
end)
BGetPos.MouseButton1Click:Connect(function()
    local root = getRoot()
    if not root then plrOut("No character.", false); return end
    local p = root.Position
    txIn.Text = ("%.1f"):format(p.X)
    tyIn.Text = ("%.1f"):format(p.Y)
    tzIn.Text = ("%.1f"):format(p.Z)
    plrOut(("Position: %.2f, %.2f, %.2f"):format(p.X, p.Y, p.Z), true)
end)

-- ── Character info ────────────────────────────────────────────────────────────
local BCharInfo = B(P4, "Character Info", UDim2.new(0,120,0,24), UDim2.new(0,0,0,196), C.GREY)
BCharInfo.TextSize = 11; hov(BCharInfo, C.GREY, C.GRYHV)
BCharInfo.MouseButton1Click:Connect(function()
    local char = getChar()
    local hum  = getHum()
    local root = getRoot()
    if not char then plrOut("No character.", false); return end
    local parts = 0
    for _, p in char:GetDescendants() do if p:IsA("BasePart") then parts+=1 end end
    plrOut(table.concat({
        "Name: " .. LP.Name .. " (@" .. LP.DisplayName .. ")",
        "Health: " .. (hum and ("%.1f/%.1f"):format(hum.Health,hum.MaxHealth) or "N/A"),
        "WalkSpeed: " .. (hum and hum.WalkSpeed or "N/A"),
        "JumpPower: " .. (hum and hum.JumpPower or "N/A"),
        "Parts: " .. parts,
        "Pos: " .. (root and ("%.1f %.1f %.1f"):format(root.Position.X,root.Position.Y,root.Position.Z) or "N/A"),
    }, "\n"), true)
end)
