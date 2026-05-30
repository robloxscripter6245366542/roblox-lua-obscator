-- ── Drag — PC mouse + iPad touch ─────────────────────────────────────────────
local dragging  = false
local dragStart = nil
local dragPos   = nil

TBAR.InputBegan:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = inp.Position
        dragPos   = WIN.Position
    end
end)

UIS.InputChanged:Connect(function(inp)
    if not dragging then return end
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
        local delta = inp.Position - dragStart
        WIN.Position = UDim2.new(
            dragPos.X.Scale, dragPos.X.Offset + delta.X,
            dragPos.Y.Scale, dragPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ── Minimise / restore ────────────────────────────────────────────────────────
local minimised = false

BtnMin.MouseButton1Click:Connect(function()
    minimised = not minimised
    if minimised then
        tw(WIN, {Size = UDim2.new(0,650,0,44)}, TS2)
        BODY.Visible = false
        SIDE.Visible = false
        BtnMin.Text  = "□"
    else
        tw(WIN, {Size = UDim2.new(0,650,0,530)}, TS2)
        task.delay(0.12, function()
            BODY.Visible = true
            SIDE.Visible = true
        end)
        BtnMin.Text = "—"
    end
end)

-- ── Keyboard shortcut: F5 = refresh / re-run current tab ─────────────────────
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.F5 then
        -- flash current page to indicate refresh
        if pages[curPage] then
            tw(pages[curPage], {BackgroundTransparency=0.4})
            task.delay(0.12, function() tw(pages[curPage],{BackgroundTransparency=1}) end)
        end
    end
    -- F1-F9: jump to tab
    for i = 1, 9 do
        if inp.KeyCode == Enum.KeyCode["F"..i] and pages[i] then
            showPage(i); break
        end
    end
end)

-- ── Init: show first page, run auto-checks ────────────────────────────────────
showPage(1)

-- Checker auto-build
if switchSub then switchSub(1) end
if buildList  then buildList(1) end

-- Environ auto-run
task.spawn(function()
    if runCheck then runCheck() end
end)

-- Build script hub listing
if buildScripts then buildScripts("") end

-- Refresh player list
if refreshPlrs then refreshPlrs() end

-- Done notification
task.delay(0.5, function()
    notify("Nexus Executor", "Loaded ✓  " .. tabN .. " tabs ready", 4)
end)
