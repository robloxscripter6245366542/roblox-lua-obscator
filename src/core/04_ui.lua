-- ── UI Helper Library ─────────────────────────────────────────────────────────
-- All Instance-creation wrappers. `isMobile` and `WIN_W/H/SIDE_W` are
-- already in scope (defined in 01_services.lua).

-- UICorner
local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 7)
    c.Parent = p
end

-- UIStroke
local function stroke(p, col, th, lineStyle)
    local s = Instance.new("UIStroke")
    s.Color = col or C.BDR
    s.Thickness = th or 1.2
    if lineStyle then s.LineJoinMode = lineStyle end
    s.Parent = p
end

-- UIPadding
local function pad(p, v, h)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, v or 6)
    u.PaddingBottom = UDim.new(0, v or 6)
    u.PaddingLeft   = UDim.new(0, h or v or 9)
    u.PaddingRight  = UDim.new(0, h or v or 9)
    u.Parent = p
end

-- UIListLayout — horizontal
local function listH(p, sp, xa, ya)
    local l = Instance.new("UIListLayout")
    l.FillDirection  = Enum.FillDirection.Horizontal
    l.SortOrder      = Enum.SortOrder.LayoutOrder
    l.Padding        = UDim.new(0, sp or 4)
    if xa then l.HorizontalAlignment = xa end
    if ya then l.VerticalAlignment   = ya end
    l.Parent = p
end

-- UIListLayout — vertical
local function listV(p, sp, ya)
    local l = Instance.new("UIListLayout")
    l.FillDirection  = Enum.FillDirection.Vertical
    l.SortOrder      = Enum.SortOrder.LayoutOrder
    l.Padding        = UDim.new(0, sp or 4)
    if ya then l.HorizontalAlignment = ya end
    l.Parent = p
end

-- UIGridLayout
local function grid(p, cellSz, cellPad)
    local g = Instance.new("UIGridLayout")
    g.CellSize    = cellSz or UDim2.new(0, 100, 0, 80)
    g.CellPadding = cellPad or UDim2.new(0, 4, 0, 4)
    g.SortOrder   = Enum.SortOrder.LayoutOrder
    g.Parent = p
    return g
end

-- UIAspectRatioConstraint
local function aspect(p, ratio)
    local a = Instance.new("UIAspectRatioConstraint")
    a.AspectRatio = ratio or 1
    a.Parent = p
end

-- UIScale
local function scale(p, s)
    local u = Instance.new("UIScale")
    u.Scale = s or 1
    u.Parent = p
    return u
end

-- Frame
local function F(par, sz, pos, col, nm)
    local f = Instance.new("Frame")
    f.Size             = sz
    f.Position         = pos or UDim2.new(0, 0, 0, 0)
    f.BackgroundColor3 = col or C.PANEL
    f.BorderSizePixel  = 0
    f.Name             = nm or "F"
    f.Parent           = par
    return f
end

-- TextLabel
local function L(par, txt, sz, pos, col, fnt, ts, xa, ya)
    local l = Instance.new("TextLabel")
    l.Size               = sz
    l.Position           = pos or UDim2.new(0, 0, 0, 0)
    l.BackgroundTransparency = 1
    l.Text               = txt or ""
    l.TextColor3         = col or C.TXT
    l.Font               = fnt or FN
    l.TextSize           = ts or 13
    l.TextXAlignment     = xa or Enum.TextXAlignment.Left
    l.TextYAlignment     = ya or Enum.TextYAlignment.Center
    l.TextTruncate       = Enum.TextTruncate.AtEnd
    l.RichText           = false
    l.Parent             = par
    return l
end

-- TextLabel with RichText
local function LR(par, txt, sz, pos, col, fnt, ts, xa)
    local l = L(par, txt, sz, pos, col, fnt, ts, xa)
    l.RichText = true
    return l
end

-- TextButton
local function B(par, txt, sz, pos, bg, tc)
    local b = Instance.new("TextButton")
    b.Size             = sz
    b.Position         = pos or UDim2.new(0, 0, 0, 0)
    b.BackgroundColor3 = bg or C.ACC
    b.BorderSizePixel  = 0
    b.Text             = txt or ""
    b.TextColor3       = tc or C.TXT
    b.Font             = FB
    b.TextSize         = 12
    b.AutoButtonColor  = false
    b.Parent           = par
    corner(b, 6)
    return b
end

-- TextBox — multiline input editor
local function IN(par, ph, sz, pos, multiline)
    local b = Instance.new("TextBox")
    b.Size               = sz
    b.Position           = pos or UDim2.new(0, 0, 0, 0)
    b.BackgroundColor3   = C.EDIT
    b.BorderSizePixel    = 0
    b.Text               = ""
    b.PlaceholderText    = ph or ""
    b.TextColor3         = C.TXT
    b.PlaceholderColor3  = C.TXTS
    b.Font               = FC
    b.TextSize           = 12
    b.TextXAlignment     = Enum.TextXAlignment.Left
    b.TextYAlignment     = Enum.TextYAlignment.Top
    b.ClearTextOnFocus   = false
    b.MultiLine          = multiline ~= false
    b.TextWrapped        = true
    b.ClipsDescendants   = true
    b.Parent             = par
    corner(b, 6)
    stroke(b, C.BDR, 1)
    pad(b, 6, 10)
    return b
end

-- TextBox — single-line input
local function INS(par, ph, sz, pos)
    local b = IN(par, ph, sz, pos, false)
    b.TextYAlignment = Enum.TextYAlignment.Center
    return b
end

-- TextBox — output console (read-only)
local function OUT(par, sz, pos, ph)
    local b = Instance.new("TextBox")
    b.Size               = sz
    b.Position           = pos or UDim2.new(0, 0, 0, 0)
    b.BackgroundColor3   = C.CON
    b.BorderSizePixel    = 0
    b.Text               = ""
    b.PlaceholderText    = ph or "> output…"
    b.TextColor3         = C.GRN
    b.PlaceholderColor3  = C.TXTD
    b.Font               = FC
    b.TextSize           = 11
    b.TextXAlignment     = Enum.TextXAlignment.Left
    b.TextYAlignment     = Enum.TextYAlignment.Top
    b.ClearTextOnFocus   = false
    b.MultiLine          = true
    b.TextWrapped        = true
    b.TextEditable       = false
    b.ClipsDescendants   = true
    b.Parent             = par
    corner(b, 6)
    stroke(b, C.BDR, 1)
    pad(b, 6, 10)
    return b
end

-- Single-line, timestamped status console. Returns a writer fn(msg, ok)
-- that colours the box green on success / red on failure.
local function statusOut(par, sz, pos, ph)
    local box = OUT(par, sz, pos, ph)
    return function(msg, ok)
        box.TextColor3 = ok and C.GRN or C.RED
        box.Text = ts() .. tostring(msg)
    end
end

-- Remove every child of a layout container except its UIListLayout.
local function clearLayout(container)
    for _, ch in container:GetChildren() do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
end

-- Assign sequential LayoutOrder + a common TextSize to a row of buttons.
local function styleRow(btns, textSize)
    for i, b in btns do
        b.LayoutOrder = i
        b.TextSize    = textSize or 11
    end
    return btns
end

-- ScrollingFrame (auto canvas, vertical by default)
local function SCR(par, sz, pos, barThick)
    local s = Instance.new("ScrollingFrame")
    s.Size                  = sz
    s.Position              = pos or UDim2.new(0, 0, 0, 0)
    s.BackgroundTransparency = 1
    s.BorderSizePixel       = 0
    s.ScrollBarThickness    = barThick or (isMobile and 2 or 3)
    s.ScrollBarImageColor3  = C.ACC
    s.CanvasSize            = UDim2.new(0, 0, 0, 0)
    s.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    s.Parent                = par
    return s
end

-- Hover tween helper — touch devices get press-feedback instead of hover
local function hov(btn, normal, hovered)
    if not isMobile then
        btn.MouseEnter:Connect(function()
            tw(btn, {BackgroundColor3 = hovered})
        end)
        btn.MouseLeave:Connect(function()
            tw(btn, {BackgroundColor3 = normal})
        end)
    end
    -- Press feedback works on all devices
    btn.MouseButton1Down:Connect(function()
        tw(btn, {BackgroundColor3 = hovered})
    end)
    btn.MouseButton1Up:Connect(function()
        tw(btn, {BackgroundColor3 = normal})
    end)
end

-- Hover with text color change
local function hovFull(btn, nBg, hBg, nTxt, hTxt)
    if not isMobile then
        btn.MouseEnter:Connect(function()  tw(btn, {BackgroundColor3=hBg, TextColor3=hTxt or C.WHT}) end)
        btn.MouseLeave:Connect(function()  tw(btn, {BackgroundColor3=nBg, TextColor3=nTxt or C.TXT}) end)
    end
    btn.MouseButton1Down:Connect(function() tw(btn, {BackgroundColor3=hBg}) end)
    btn.MouseButton1Up:Connect(function()   tw(btn, {BackgroundColor3=nBg}) end)
end

-- Horizontal row container.
-- On mobile: uses a horizontal ScrollingFrame (invisible scrollbar) so button
-- rows that exceed the content width can be swiped left/right.
-- On desktop: plain transparent frame with UIListLayout.
local function rowBar(par, yOff, h)
    if isMobile then
        local r = Instance.new("ScrollingFrame")
        r.Size                  = UDim2.new(1, 0, 0, h or 26)
        r.Position              = UDim2.new(0, 0, 0, yOff or 0)
        r.BackgroundTransparency = 1
        r.BorderSizePixel       = 0
        r.ScrollBarThickness    = 0            -- invisible — swipe gesture only
        r.ScrollingDirection    = Enum.ScrollingDirection.X
        r.CanvasSize            = UDim2.new(0, 0, 0, 0)
        r.AutomaticCanvasSize   = Enum.AutomaticSize.X
        r.Parent                = par
        listH(r, 4)
        return r
    else
        local r = F(par, UDim2.new(1, 0, 0, h or 26), UDim2.new(0, 0, 0, yOff or 0), C.BLK)
        r.BackgroundTransparency = 1
        listH(r, 4)
        return r
    end
end

-- Section header (coloured panel with label)
local function sectionHdr(par, txt, col)
    local r = F(par, UDim2.new(1, -4, 0, 22), nil, col or C.PANEL)
    corner(r, 5)
    L(r, "  " .. txt, UDim2.new(1, 0, 1, 0), nil, C.PURP, FB, 11)
    return r
end

-- Status dot (small circle indicator)
local function dot(par, sz, pos, col)
    local d = F(par, sz or UDim2.new(0, 8, 0, 8), pos or UDim2.new(0, 0, 0, 0), col or C.GREY)
    corner(d, 99)
    return d
end

-- Badge / pill label
local function pill(par, txt, col, sz, pos)
    local bg = F(par, sz or UDim2.new(0, 60, 0, 18), pos, col or C.GREY)
    corner(bg, 4)
    L(bg, txt, UDim2.new(1, 0, 1, 0), nil, C.WHT, FB, 10, Enum.TextXAlignment.Center)
    return bg
end

-- Divider line
local function divider(par, col)
    local d = F(par, UDim2.new(1, -4, 0, 1), nil, col or C.BDR)
    d.BackgroundTransparency = 0.5
    return d
end

-- Image button
local function IMG(par, assetId, sz, pos)
    local i = Instance.new("ImageButton")
    i.Size = sz; i.Position = pos or UDim2.new(0, 0, 0, 0)
    i.BackgroundTransparency = 1; i.BorderSizePixel = 0
    i.Image = "rbxassetid://" .. assetId; i.Parent = par
    return i
end

-- Tooltip (desktop hover only — on mobile tooltips are inaccessible)
local function tooltip(btn, text, yOff)
    if isMobile then return end
    local tip = Instance.new("TextLabel")
    tip.Size = UDim2.new(0, #text * 7 + 16, 0, 22)
    tip.Position = UDim2.new(0, 0, 1, yOff or 4)
    tip.BackgroundColor3 = C.PANEL; tip.TextColor3 = C.TXT
    tip.Text = text; tip.Font = FN; tip.TextSize = 11
    tip.BorderSizePixel = 0; tip.ZIndex = 20; tip.Visible = false
    tip.Parent = btn; corner(tip, 5); stroke(tip, C.BDR, 1)
    btn.MouseEnter:Connect(function()  tip.Visible = true  end)
    btn.MouseLeave:Connect(function()  tip.Visible = false end)
    return tip
end

-- Toggle button (stateful on/off)
local function toggleButton(par, txt, sz, pos, onCol, offCol)
    local state = false
    local b = B(par, txt, sz, pos, offCol or C.GREY)
    local function refresh()
        tw(b, {BackgroundColor3 = state and (onCol or C.GRN) or (offCol or C.GREY)})
        b.Text = (state and "■ " or "○ ") .. txt
    end
    b.MouseButton1Click:Connect(function()
        state = not state; refresh()
    end)
    local function getState() return state end
    local function setState(v) state = v; refresh() end
    return b, getState, setState
end

-- Number stepper (+/- with label)
local function stepper(par, label, default, min, max, step, sz, pos)
    local container = F(par, sz or UDim2.new(0, 200, 0, 28), pos, C.PANEL)
    corner(container, 6)
    local val = default or 0
    L(container, label, UDim2.new(0, 80, 1, 0), UDim2.new(0, 4, 0, 0), C.TXTS, FN, 11)
    local valLbl = L(container, tostring(val), UDim2.new(0, 50, 1, 0),
        UDim2.new(0, 84, 0, 0), C.TXT, FB, 12, Enum.TextXAlignment.Center)
    local bM = B(container, "−", UDim2.new(0, 24, 0, 20), UDim2.new(0, 134, 0, 4), C.GREY)
    local bP = B(container, "+", UDim2.new(0, 24, 0, 20), UDim2.new(0, 162, 0, 4), C.ACC)
    hov(bM, C.GREY, C.GRYHV); hov(bP, C.ACC, C.ACCHV)
    local onChange = nil
    bM.MouseButton1Click:Connect(function()
        val = math.max(min or -math.huge, val - (step or 1))
        valLbl.Text = tostring(val)
        if onChange then onChange(val) end
    end)
    bP.MouseButton1Click:Connect(function()
        val = math.min(max or math.huge, val + (step or 1))
        valLbl.Text = tostring(val)
        if onChange then onChange(val) end
    end)
    return container, function() return val end, function(fn) onChange = fn end
end

-- Card (panel with title + optional subtitle)
local function card(par, title, subtitle, h)
    local r = F(par, UDim2.new(1, -4, 0, h or 54), nil, C.PANEL)
    corner(r, 7); stroke(r, Color3.fromRGB(28, 40, 72), 1)
    L(r, title, UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 0, 5), C.TXT, FB, 13)
    if subtitle then
        L(r, subtitle, UDim2.new(1, -16, 0, 16), UDim2.new(0, 8, 0, 26), C.TXTS, FN, 10)
    end
    return r
end

-- Util row (card + action button)
local function utilRow(par, title, desc, btnTxt, btnCol, action)
    local Row = card(par, title, desc, 54)
    local bc  = btnCol or C.ACC
    local hc  = Color3.fromRGB(
        math.min(255, bc.R * 255 + 30),
        math.min(255, bc.G * 255 + 30),
        math.min(255, bc.B * 255 + 30)
    )
    local btn = B(Row, btnTxt, UDim2.new(0, 88, 0, 26), UDim2.new(1, -96, 0.5, -13), bc)
    btn.TextSize = 11; hov(btn, bc, hc)
    btn.MouseButton1Click:Connect(function()
        local ok2, res = pcall(action)
        return ok2, res
    end)
    return Row, btn
end
