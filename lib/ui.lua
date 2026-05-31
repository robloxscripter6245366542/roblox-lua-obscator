local SS = _G._SS
local C  = SS.C
local TS = SS.TS
local TF = SS.TF

local function tw(o, p, ti) TS:Create(o, ti or TF, p):Play() end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 7); c.Parent = p
end

local function stroke(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or C.BORDER; s.Thickness = th or 1.2; s.Parent = p
end

local function pad(p, v, h)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, v or 6)
    u.PaddingBottom = UDim.new(0, v or 6)
    u.PaddingLeft   = UDim.new(0, h or v or 9)
    u.PaddingRight  = UDim.new(0, h or v or 9)
    u.Parent = p
end

local function listH(p, sp)
    local l = Instance.new("UIListLayout")
    l.FillDirection = Enum.FillDirection.Horizontal
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, sp or 4)
    l.Parent = p
end

local function listV(p, sp)
    local l = Instance.new("UIListLayout")
    l.FillDirection = Enum.FillDirection.Vertical
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, sp or 4)
    l.Parent = p
end

local function Frm(parent, sz, pos, col, name)
    local f = Instance.new("Frame")
    f.Size = sz; f.Position = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3 = col or C.PANEL
    f.BorderSizePixel = 0; f.Name = name or "F"
    f.Parent = parent; return f
end

local function Lbl(parent, text, sz, pos, col, fnt, ts, xa)
    local l = Instance.new("TextLabel")
    l.Size = sz; l.Position = pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency = 1; l.Text = text or ""
    l.TextColor3 = col or C.TXT
    l.Font = fnt or SS.FN; l.TextSize = ts or 13
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Parent = parent; return l
end

local function Btn(parent, text, sz, pos, bg, tc)
    local b = Instance.new("TextButton")
    b.Size = sz; b.Position = pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3 = bg or C.ACC
    b.BorderSizePixel = 0; b.Text = text or ""
    b.TextColor3 = tc or C.TXT; b.Font = SS.FB; b.TextSize = 13
    b.AutoButtonColor = false
    b.Parent = parent; corner(b, 6); return b
end

local function Inp(parent, ph, sz, pos)
    local b = Instance.new("TextBox")
    b.Size = sz; b.Position = pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3 = C.EDIT; b.BorderSizePixel = 0; b.Text = ""
    b.PlaceholderText = ph or ""; b.TextColor3 = C.TXT; b.PlaceholderColor3 = C.TXTS
    b.Font = SS.FC; b.TextSize = 13
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.TextYAlignment = Enum.TextYAlignment.Top
    b.ClearTextOnFocus = false; b.MultiLine = true
    b.TextWrapped = true; b.ClipsDescendants = true
    b.Parent = parent; corner(b, 6); stroke(b, C.BORDER, 1); pad(b, 7, 10); return b
end

local function Con(parent, sz, pos)
    local b = Instance.new("TextBox")
    b.Size = sz; b.Position = pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3 = C.CON; b.BorderSizePixel = 0; b.Text = ""
    b.PlaceholderText = "> output..."; b.TextColor3 = C.GREEN; b.PlaceholderColor3 = C.TXTD
    b.Font = SS.FC; b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.TextYAlignment = Enum.TextYAlignment.Top
    b.ClearTextOnFocus = false; b.MultiLine = true
    b.TextWrapped = true; b.TextEditable = false; b.ClipsDescendants = true
    b.Parent = parent; corner(b, 6); stroke(b, C.BORDER, 1); pad(b, 7, 10); return b
end

local function Scr(parent, sz, pos)
    local s = Instance.new("ScrollingFrame")
    s.Size = sz; s.Position = pos or UDim2.new(0,0,0,0)
    s.BackgroundTransparency = 1; s.BorderSizePixel = 0
    s.ScrollBarThickness = 3; s.ScrollBarImageColor3 = C.ACC
    s.CanvasSize = UDim2.new(0,0,0,0)
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    s.Parent = parent; return s
end

local function hov(btn, n, h)
    btn.MouseEnter:Connect(function()       tw(btn, {BackgroundColor3=h}) end)
    btn.MouseLeave:Connect(function()       tw(btn, {BackgroundColor3=n}) end)
    btn.MouseButton1Down:Connect(function() tw(btn, {BackgroundColor3=n}) end)
    btn.MouseButton1Up:Connect(function()   tw(btn, {BackgroundColor3=h}) end)
end

local function rowBar(parent, yOff)
    local r = Frm(parent, UDim2.new(1,0,0,26), UDim2.new(0,0,0,yOff), Color3.fromRGB(0,0,0))
    r.BackgroundTransparency = 1; listH(r, 4); return r
end

SS.tw     = tw
SS.corner = corner
SS.stroke = stroke
SS.pad    = pad
SS.listH  = listH
SS.listV  = listV
SS.Frm    = Frm
SS.Lbl    = Lbl
SS.Btn    = Btn
SS.Inp    = Inp
SS.Con    = Con
SS.Scr    = Scr
SS.hov    = hov
SS.rowBar = rowBar
