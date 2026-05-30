-- ── Drag — PC mouse + all touch devices (Delta iOS/Android/iPad) ─────────────
-- Uses absolute pixel coordinates so clamping to screen bounds is exact.

local _dragging  = false
local _dragWinX  = 0
local _dragWinY  = 0
local _dragTchX  = 0
local _dragTchY  = 0

TBAR.InputBegan:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        -- On multi-touch screens ignore secondary fingers while already dragging
        if _dragging and t == Enum.UserInputType.Touch then return end
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
        local dx   = inp.Position.X - _dragTchX
        local dy   = inp.Position.Y - _dragTchY
        local vp   = workspace.CurrentCamera.ViewportSize
        local winSz = WIN.AbsoluteSize
        local newX = math.clamp(_dragWinX + dx, 0, math.max(0, vp.X - winSz.X))
        local newY = math.clamp(_dragWinY + dy, 0, math.max(0, vp.Y - winSz.Y))
        WIN.Position = UDim2.new(0, newX, 0, newY)
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
        SIDE.Visible = false
        BtnMin.Text  = "□"
    else
        tw(WIN, {Size = UDim2.new(0, WIN_W, 0, WIN_H)}, TS2)
        task.delay(0.12, function()
            BODY.Visible = true
            SIDE.Visible = true
        end)
        BtnMin.Text = "—"
    end
end)

-- ── Keyboard shortcuts (desktop only — mobile has no physical keyboard) ────────
if not isMobile then
    UIS.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        -- F5 = flash current tab (visual "refresh" hint)
        if inp.KeyCode == Enum.KeyCode.F5 then
            if pages[curPage] then
                tw(pages[curPage], {BackgroundTransparency = 0.4})
                task.delay(0.12, function()
                    tw(pages[curPage], {BackgroundTransparency = 1})
                end)
            end
        end
        -- F1–F9: jump directly to tab
        for i = 1, 9 do
            if inp.KeyCode == Enum.KeyCode["F" .. i] and pages[i] then
                showPage(i); break
            end
        end
    end)
end

-- ── Initialise UI ─────────────────────────────────────────────────────────────
showPage(1)

-- Checker sub-tab default
if switchSub  then switchSub(1)  end
if buildList  then buildList(1)  end

-- Environ auto-run
task.spawn(function()
    if runCheck then runCheck() end
end)

-- Script hub listing
if buildScripts then buildScripts("") end

-- Server tab player list
if refreshPlrs  then refreshPlrs()   end

-- Loaded notification
task.delay(0.5, function()
    notify("Nexus Executor",
        string.format("Loaded ✓  %d tabs  |  %s  |  %s",
            tabN,
            SESSION.executor,
            SESSION.platform),
        5)
end)
