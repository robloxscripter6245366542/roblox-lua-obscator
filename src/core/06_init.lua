-- ── Drag — PC mouse + touch (Delta iOS/Android/iPad) ─────────────────────────
-- Stores start position as absolute pixels; delta is applied in pixel space.
-- Clamps to viewport so the window can never leave the screen.
-- Ignores secondary touches while dragging (multi-touch safe).

local _dragging = false
local _dragWinX, _dragWinY = 0, 0
local _dragTchX, _dragTchY = 0, 0

TBAR.InputBegan:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        if _dragging and t == Enum.UserInputType.Touch then return end   -- ignore 2nd finger
        _dragging  = true
        _dragTchX  = inp.Position.X
        _dragTchY  = inp.Position.Y
        _dragWinX  = WIN.AbsolutePosition.X
        _dragWinY  = WIN.AbsolutePosition.Y
    end
end)

UIS.InputChanged:Connect(function(inp)
    if not _dragging then return end
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
        local dx  = inp.Position.X - _dragTchX
        local dy  = inp.Position.Y - _dragTchY
        local vp  = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
                    or Vector2.new(WIN_W, WIN_H)
        local wsz = WIN.AbsoluteSize
        local nx  = math.clamp(_dragWinX + dx, 0, math.max(0, vp.X - wsz.X))
        local ny  = math.clamp(_dragWinY + dy, 0, math.max(0, vp.Y - wsz.Y))
        WIN.Position = UDim2.new(0, nx, 0, ny)
    end
end)

UIS.InputEnded:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        _dragging = false
    end
end)

-- ── Minimise / restore ────────────────────────────────────────────────────────
local _minimised = false

BtnMin.MouseButton1Click:Connect(function()
    _minimised = not _minimised
    if _minimised then
        tw(WIN, {Size = UDim2.new(0, WIN_W, 0, 44)}, TS2)
        BODY.Visible = false
        if SIDE   then SIDE.Visible   = false end
        if TABBAR then TABBAR.Visible = false end
        BtnMin.Text = "□"
    else
        tw(WIN, {Size = UDim2.new(0, WIN_W, 0, WIN_H)}, TS2)
        task.delay(0.12, function()
            BODY.Visible = true
            if SIDE   then SIDE.Visible   = true end
            if TABBAR then TABBAR.Visible = true end
        end)
        BtnMin.Text = "—"
    end
end)

-- ── Keyboard shortcuts (desktop only) ────────────────────────────────────────
if not isMobile then
    UIS.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode == Enum.KeyCode.F5 then
            if pages[curPage] then
                tw(pages[curPage],{BackgroundTransparency=0.4})
                task.delay(0.12,function() tw(pages[curPage],{BackgroundTransparency=1}) end)
            end
        end
        for i = 1, 9 do
            if inp.KeyCode == Enum.KeyCode["F"..i] and pages[i] then
                showPage(i); break
            end
        end
    end)
end

-- ── Init ─────────────────────────────────────────────────────────────────────
showPage(1)

if switchSub   then switchSub(1)   end
if buildList   then buildList(1)   end
if buildScripts then buildScripts("") end
if refreshPlrs  then refreshPlrs()   end

task.spawn(function()
    if runCheck then runCheck() end
end)

task.delay(0.5, function()
    notify("Nexus Executor",
        ("Loaded ✓  %d tabs  |  %s  |  %s"):format(
            tabN, SESSION.executor, SESSION.platform), 5)
end)
