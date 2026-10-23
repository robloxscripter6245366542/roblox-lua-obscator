--[[
    🌙  L U N A R   U I   —  Clean Glass · Clean Pink
    ────────────────────────────────────────────────────────────────────
    A self-contained premium Roblox UI library (WindUI-style API).
    No external loadstring required — paste & run on any executor.

    HIGHLIGHTS
      • Glassmorphism theme, clean pink accents, fully themeable.
      • Chainable, metatable-driven API:  Window → Section → Tab → Group/Section → Elements
      • Elements: Section, Group, Space, Divider, Label, Paragraph, Image,
                  Button, Toggle, Slider, Dropdown (single/multi/advanced),
                  Input (+ Textarea), Colorpicker, Keybind.
      • Notify, Popup, Tag, Search bar, Open button, Toggle key.
      • Config / Flags system (save & load to file).
      • ⭐ Register ANY custom element and it "bends" with the UI:
             Lunar:AddElement("MyThing", function(container, cfg) ... end)
             tab:MyThing({ ... })        -- available on every container

    QUICK START (full demo at the very bottom of this file):
        local Lunar  = loadstring(...)()  -- or require this module
        local Window = Lunar:CreateWindow({ Title = "Lunar Hub" })
        local Tab    = Window:Tab({ Title = "Main", Icon = "home" })
        Tab:Button({ Title = "Click me", Callback = function() end })
--]]

local Lunar = {}
Lunar.Version = "2.0.0"

do
    --==================================================================
    -- SERVICES  &  EXECUTOR COMPATIBILITY
    --==================================================================
    local cloneref = cloneref or clonereference or function(o) return o end
    local Players          = cloneref(game:GetService("Players"))
    local UserInputService = cloneref(game:GetService("UserInputService"))
    local TweenService     = cloneref(game:GetService("TweenService"))
    local RunService       = cloneref(game:GetService("RunService"))
    local HttpService      = cloneref(game:GetService("HttpService"))
    local StarterGui       = cloneref(game:GetService("StarterGui"))
    local LocalPlayer      = Players.LocalPlayer

    local setclip = setclipboard or (syn and syn.set_clipboard) or function() end
    local function protect(gui)
        pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
        pcall(function() if protectgui then protectgui(gui) end end)
    end
    local function guiParent()
        local ok, h = pcall(function() return gethui and gethui() end)
        if ok and h then return h end
        local ok2, cg = pcall(function() return cloneref(game:GetService("CoreGui")) end)
        if ok2 and cg then return cg end
        return LocalPlayer:WaitForChild("PlayerGui")
    end

    -- file api (all guarded)
    local hasFiles = (writefile and readfile and isfile) and true or false
    local function safeMakeFolder(p) pcall(function() if makefolder and (not (isfolder and isfolder(p))) then makefolder(p) end end) end
    local function safeWrite(p, d) local ok = pcall(function() writefile(p, d) end) return ok end
    local function safeRead(p) local ok, r = pcall(function() return readfile(p) end) if ok then return r end end
    local function safeList(p) local ok, r = pcall(function() return listfiles(p) end) if ok then return r else return {} end end

    --==================================================================
    -- THEMES  (clean glass · clean pink by default)
    --==================================================================
    Lunar.Themes = {
        Sakura = {  -- default clean-glass pink
            Window      = Color3.fromRGB(17, 13, 23),
            WindowGlow  = Color3.fromRGB(38, 20, 40),
            Sidebar     = Color3.fromRGB(20, 15, 27),
            Topbar      = Color3.fromRGB(19, 14, 25),
            Glass       = Color3.fromRGB(255, 255, 255),  -- frosted overlay tint
            Card        = Color3.fromRGB(255, 255, 255),
            Elevated    = Color3.fromRGB(34, 24, 44),
            Accent      = Color3.fromRGB(244, 114, 182),
            AccentSoft  = Color3.fromRGB(255, 170, 214),
            AccentDeep  = Color3.fromRGB(170, 58, 128),
            Text        = Color3.fromRGB(246, 236, 247),
            SubText     = Color3.fromRGB(199, 176, 205),
            Muted       = Color3.fromRGB(140, 116, 150),
            Stroke      = Color3.fromRGB(255, 255, 255),  -- glass rim
            Success     = Color3.fromRGB(86, 222, 156),
            Danger      = Color3.fromRGB(244, 84, 120),
            Warning     = Color3.fromRGB(240, 176, 72),
        },
        Midnight = {
            Window = Color3.fromRGB(12,13,20), WindowGlow = Color3.fromRGB(24,28,52),
            Sidebar = Color3.fromRGB(14,15,24), Topbar = Color3.fromRGB(14,15,24),
            Glass = Color3.fromRGB(255,255,255), Card = Color3.fromRGB(255,255,255),
            Elevated = Color3.fromRGB(26,28,44), Accent = Color3.fromRGB(120,140,255),
            AccentSoft = Color3.fromRGB(170,185,255), AccentDeep = Color3.fromRGB(70,84,190),
            Text = Color3.fromRGB(236,238,248), SubText = Color3.fromRGB(176,182,205),
            Muted = Color3.fromRGB(116,122,150), Stroke = Color3.fromRGB(255,255,255),
            Success = Color3.fromRGB(86,222,156), Danger = Color3.fromRGB(244,84,120),
            Warning = Color3.fromRGB(240,176,72),
        },
    }
    local Theme = Lunar.Themes.Sakura   -- active theme (module-wide)

    local FONT      = Enum.Font.Gotham
    local FONT_MED  = Enum.Font.GothamMedium
    local FONT_BOLD = Enum.Font.GothamBold

    --==================================================================
    -- LOW-LEVEL BUILDERS
    --==================================================================
    local function New(class, props, kids)
        local o = Instance.new(class)
        if props then for k, v in pairs(props) do if k ~= "Parent" then o[k] = v end end end
        if kids then for _, c in ipairs(kids) do c.Parent = o end end
        if props and props.Parent then o.Parent = props.Parent end
        return o
    end
    local function Corner(p, r) return New("UICorner", { CornerRadius = UDim.new(0, r or 10), Parent = p }) end
    local function Stroke(p, c, t, tr)
        return New("UIStroke", { Color = c or Theme.Stroke, Thickness = t or 1,
            Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p })
    end
    local function Gradient(p, c1, c2, rot, transSeq)
        return New("UIGradient", {
            Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2) }),
            Rotation = rot or 90, Transparency = transSeq or NumberSequence.new(0), Parent = p })
    end
    local function Pad(p, l, t, r, b)
        return New("UIPadding", {
            PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or l or 0),
            PaddingTop = UDim.new(0, t or l or 0), PaddingBottom = UDim.new(0, b or t or l or 0), Parent = p })
    end
    local function List(p, pad, dir)
        return New("UIListLayout", { Padding = UDim.new(0, pad or 8),
            FillDirection = dir or Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder, Parent = p })
    end
    local function Tween(o, t, props, style, dir)
        local tw = TweenService:Create(o, TweenInfo.new(t or 0.2,
            style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props)
        tw:Play(); return tw
    end

    -- frosted-glass surface (the signature look)
    local function Glass(inst, tint, opacity)
        inst.BackgroundColor3 = tint or Theme.Glass
        inst.BackgroundTransparency = opacity or 0.93
        local g = Gradient(inst, Color3.fromRGB(255, 255, 255), Color3.fromRGB(210, 205, 225), 55)
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.86), NumberSequenceKeypoint.new(1, 0.97) })
        local s = Stroke(inst, Theme.Stroke, 1, 0.82)
        -- rim-light gradient on the stroke
        local sg = New("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(255,255,255)),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.5, 0.9),
                NumberSequenceKeypoint.new(1, 0.75) }),
            Rotation = 90, Parent = s })
        return inst, s, g
    end

    local function Shadow(parent, spread, transparency, zi)
        return New("ImageLabel", {
            Name = "Shadow", BackgroundTransparency = 1, Image = "rbxassetid://5028857084",
            ImageColor3 = Color3.fromRGB(0,0,0), ImageTransparency = transparency or 0.4,
            ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(24, 24, 276, 276),
            Size = UDim2.new(1, spread or 48, 1, spread or 48),
            Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
            ZIndex = zi or 0, Parent = parent })
    end

    --==================================================================
    -- ICONS  (emoji fallback + rbxassetid/http images + custom packs)
    --==================================================================
    Lunar.Icons = {
        home="🏠", ["home-2"]="🏠", house="🏠", info="ℹ️", ["info-square"]="ℹ️", ["info-circle"]="ℹ️",
        check="✔️", ["check-square"]="✅", cursor="🖱️", ["cursor-square"]="🖱️", mouse="🖱️", button="🖱️",
        input="⌨️", password="🔑", ["password-minimalistic-input"]="🔑", slider="🎚️",
        ["square-transfer-horizontal"]="↔️", transfer="↔️", dropdown="☰", menu="☰", ["hamburger-menu"]="☰",
        file="📄", ["file-text"]="📄", ["file-plus"]="📄", ["file-pen"]="📝", ["file-cog"]="🗂️", ["file-2"]="📄",
        folder="📁", ["folder-2"]="📁", ["folder-with-files"]="📂", github="🐙", bird="🐦", droplet="💧",
        link="🔗", bell="🔔", trash="🗑️", shredder="🗑️", ["refresh-cw"]="🔄", copy="📋", crown="👑",
        moon="🌙", sparkles="✨", star="⭐", rocket="🚀", package="📦", globe="🌐", zap="⚡", palette="🎨",
        user="👤", users="👥", settings="⚙️", cog="⚙️", search="🔍", plus="➕", download="📥", upload="📤",
        eye="👁️", sun="☀️", ["sun-min"]="🌤️", ["sun-max"]="☀️", key="🔑", play="▶️", heart="💖", discord="💬",
        book="📖", diamond="💎", shield="🛡️", flame="🔥", gamepad="🎮", map="🗺️", clock="🕒",
    }
    function Lunar:AddIcons(_pack, map)
        if type(_pack) == "table" then map = _pack end
        for k, v in pairs(map or {}) do Lunar.Icons[k] = v end
    end
    local function isImage(s)
        return type(s) == "string" and (s:match("^rbxassetid://") or s:match("^http") or s:match("^rbxthumb") or s:match("^rbxasset://"))
    end
    local function resolveEmoji(name)
        if type(name) ~= "string" or name == "" then return nil end
        local base = name:match(":(.+)$") or name
        for _, suf in ipairs({ "-bold-duotone", "-bold", "-duotone", "-outline", "-fill", "-linear" }) do
            base = base:gsub(suf .. "$", "")
        end
        return Lunar.Icons[base] or Lunar.Icons[name] or Lunar.Icons[base:gsub("%-%d+$", "")]
    end
    local function makeIcon(parent, icon, size, color)
        if isImage(icon) then
            return New("ImageLabel", { BackgroundTransparency = 1, Image = icon,
                ImageColor3 = color or Theme.Text, Size = UDim2.new(0, size or 18, 0, size or 18),
                Parent = parent })
        end
        local emo = resolveEmoji(icon) or (icon ~= "" and icon) or nil
        return New("TextLabel", { BackgroundTransparency = 1, Text = emo or "",
            Font = FONT_BOLD, TextSize = (size or 18), TextColor3 = color or Theme.Text,
            Size = UDim2.new(0, size or 18, 0, size or 18), Parent = parent })
    end

    --==================================================================
    -- DRAG
    --==================================================================
    local function draggable(handle, target)
        local dragging, sp, tp
        handle.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging, sp, tp = true, i.Position, target.Position
                i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - sp
                target.Position = UDim2.new(tp.X.Scale, tp.X.Offset + d.X, tp.Y.Scale, tp.Y.Offset + d.Y)
            end
        end)
    end

    --==================================================================
    -- SERIALIZATION (for config)
    --==================================================================
    local function serialize(v)
        if typeof(v) == "Color3" then
            return { __t = "Color3", R = math.floor(v.R*255+0.5), G = math.floor(v.G*255+0.5), B = math.floor(v.B*255+0.5) }
        elseif typeof(v) == "EnumItem" then
            return { __t = "Enum", V = tostring(v) }
        elseif type(v) == "table" then
            local out = {}
            for k, val in pairs(v) do out[k] = serialize(val) end
            return out
        end
        return v
    end
    local function deserialize(v)
        if type(v) == "table" then
            if v.__t == "Color3" then return Color3.fromRGB(v.R, v.G, v.B) end
            if v.__t == "Enum" then return v.V end
            local out = {}
            for k, val in pairs(v) do out[k] = deserialize(val) end
            return out
        end
        return v
    end

    --==================================================================
    -- ELEMENT REGISTRY  (the "add anything, it bends with the UI" core)
    --==================================================================
    local ContainerMethods = {}
    local ContainerMeta = { __index = ContainerMethods }

    local function nextOrder(self)
        self._order = (self._order or 0) + 1
        return self._order
    end
    local function makeContainer(window, content, extra)
        local c = setmetatable(extra or {}, ContainerMeta)
        c.Window = window
        c.Content = content
        c._order = 0
        return c
    end

    -- Register a reusable element type available on EVERY container.
    local function register(name, fn)
        ContainerMethods[name] = function(self, cfg) return fn(self, cfg or {}) end
    end
    -- Public: users can add their own elements/metatables — they inherit theme + layout.
    function Lunar:AddElement(name, fn)
        register(name, function(self, cfg) return fn(self, cfg, self.Window) end)
        return self
    end
    -- Public helpers so custom builders match the look:
    Lunar.Build = {
        New = New, Corner = Corner, Stroke = Stroke, Gradient = Gradient, Pad = Pad,
        List = List, Tween = Tween, Glass = Glass, Icon = makeIcon, Shadow = Shadow,
    }
    function Lunar:GetTheme() return Theme end

    --==================================================================
    -- STANDARD ELEMENT PRIMITIVES
    --==================================================================
    -- Base glass row card that parents into a container.
    local function card(self, height)
        local f = New("Frame", { BackgroundColor3 = Theme.Card, Size = UDim2.new(1, 0, 0, height or 42),
            LayoutOrder = nextOrder(self), Parent = self.Content })
        Corner(f, 10); Glass(f, Theme.Card, 0.93)
        return f
    end
    local function label(parent, text, size, color, font, xoff, width)
        return New("TextLabel", { BackgroundTransparency = 1, Text = text or "",
            Font = font or FONT, TextSize = size or 14, TextColor3 = color or Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
            Position = UDim2.new(0, xoff or 0, 0, 0), Size = width or UDim2.new(1, -(xoff or 0), 1, 0),
            Parent = parent })
    end

    ------------------------------------------------------------------ Section
    register("Section", function(self, cfg)
        if cfg.Box then
            -- collapsible bordered box -> returns a NEW nested container
            local wrap = New("Frame", { BackgroundColor3 = Theme.Card, Size = UDim2.new(1, 0, 0, 40),
                AutomaticSize = Enum.AutomaticSize.Y, ClipsDescendants = true,
                LayoutOrder = nextOrder(self), Parent = self.Content })
            Corner(wrap, 12); Glass(wrap, Theme.Card, 0.95)
            if cfg.BoxBorder ~= false then Stroke(wrap, Theme.Accent, 1, 0.55) end
            local head = New("TextButton", { BackgroundTransparency = 1, Text = "",
                Size = UDim2.new(1, 0, 0, 38), Parent = wrap })
            label(head, cfg.Title or "Section", 14, Theme.Text, FONT_BOLD, 14, UDim2.new(1, -40, 1, 0))
            local chev = New("TextLabel", { BackgroundTransparency = 1, Text = "▾", Font = FONT_BOLD,
                TextSize = 13, TextColor3 = Theme.Muted, Position = UDim2.new(1, -26, 0, 0),
                Size = UDim2.new(0, 16, 0, 38), Parent = wrap })
            local inner = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 38),
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = wrap })
            List(inner, 6); Pad(inner, 12, 4, 12, 12)
            local opened = cfg.Opened ~= false
            local function apply()
                inner.Visible = opened
                Tween(chev, 0.2, { Rotation = opened and 180 or 0 })
                wrap.AutomaticSize = opened and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
                if not opened then wrap.Size = UDim2.new(1, 0, 0, 38) end
            end
            apply()
            head.MouseButton1Click:Connect(function() opened = not opened; apply() end)
            return makeContainer(self.Window, inner)
        end
        -- simple header line, added inline; returns SELF so flow continues
        local h = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, (cfg.TextSize or 15) + 12),
            LayoutOrder = nextOrder(self), Parent = self.Content })
        local bar = New("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new(0, 3, 0, (cfg.TextSize or 15)),
            Position = UDim2.new(0, 2, 0.5, -((cfg.TextSize or 15))/2), Parent = h })
        Corner(bar, 2)
        New("TextLabel", { BackgroundTransparency = 1, Text = cfg.Title or "Section",
            Font = FONT_BOLD, TextSize = cfg.TextSize or 15, TextColor3 = Theme.Text,
            TextTransparency = cfg.TextTransparency or 0, TextWrapped = true,
            TextXAlignment = cfg.Justify == "Center" and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -14, 1, 0), Parent = h })
        return self
    end)

    ------------------------------------------------------------------ Group (horizontal)
    register("Group", function(self, cfg)
        local wrap = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 42),
            AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = nextOrder(self), Parent = self.Content })
        local row = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 42),
            AutomaticSize = Enum.AutomaticSize.Y, Parent = wrap })
        local gap = 8
        local ll = List(row, gap, Enum.FillDirection.Horizontal)
        local function reflow()
            local kids = {}
            for _, ch in ipairs(row:GetChildren()) do if ch:IsA("GuiObject") then table.insert(kids, ch) end end
            local n = #kids
            if n == 0 then return end
            for _, ch in ipairs(kids) do
                ch.Size = UDim2.new(1/n, -gap * (n - 1) / n, 0, ch.Size.Y.Offset)
            end
        end
        row.ChildAdded:Connect(function() task.defer(reflow) end)
        row.ChildRemoved:Connect(function() task.defer(reflow) end)
        return makeContainer(self.Window, row)
    end)

    ------------------------------------------------------------------ Space / Divider / Label
    register("Space", function(self, cfg)
        return New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 2 * (cfg.Columns or 1)),
            LayoutOrder = nextOrder(self), Parent = self.Content })
    end)
    register("Divider", function(self, _)
        local f = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10),
            LayoutOrder = nextOrder(self), Parent = self.Content })
        New("Frame", { BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.85,
            Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0.5, 0), Parent = f })
        return f
    end)
    register("Label", function(self, cfg)
        local f = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20),
            LayoutOrder = nextOrder(self), Parent = self.Content })
        label(f, cfg.Title or cfg.Text or "", cfg.TextSize or 13, cfg.Color or Theme.SubText, FONT, 2)
        return f
    end)

    ------------------------------------------------------------------ Paragraph
    register("Paragraph", function(self, cfg)
        local c = card(self, 60)
        c.AutomaticSize = Enum.AutomaticSize.Y
        c.Size = UDim2.new(1, 0, 0, 0)
        local body = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, Parent = c })
        List(body, 4); Pad(body, 14, 12, 14, 12)
        if cfg.Image then
            local top = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, cfg.ImageSize or 40),
                LayoutOrder = 1, Parent = body })
            local img = New("ImageLabel", { BackgroundColor3 = Theme.Elevated, BackgroundTransparency = 0.3,
                Image = isImage(cfg.Image) and cfg.Image or "", Size = UDim2.new(0, cfg.ImageSize or 40, 0, cfg.ImageSize or 40),
                Parent = top })
            Corner(img, 8)
            if not isImage(cfg.Image) then makeIcon(img, cfg.Image, (cfg.ImageSize or 40) * 0.6, Theme.Accent).Position = UDim2.new(0.5, -((cfg.ImageSize or 40)*0.3), 0.5, -((cfg.ImageSize or 40)*0.3)) end
            New("TextLabel", { BackgroundTransparency = 1, Text = cfg.Title or "", Font = FONT_BOLD,
                TextSize = 15, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, (cfg.ImageSize or 40) + 10, 0, 0), Size = UDim2.new(1, -(cfg.ImageSize or 40) - 10, 1, 0),
                Parent = top })
        elseif cfg.Title then
            New("TextLabel", { BackgroundTransparency = 1, Text = cfg.Title, Font = FONT_BOLD,
                TextSize = cfg.TextSize or 15, TextColor3 = cfg.Color == "Red" and Theme.Danger or Theme.Text,
                TextXAlignment = (cfg.Justify == "Center") and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, (cfg.TextSize or 15) + 4), LayoutOrder = 1, Parent = body })
        end
        if cfg.Desc then
            New("TextLabel", { BackgroundTransparency = 1, Text = cfg.Desc, Font = FONT, TextSize = 13,
                TextColor3 = Theme.SubText, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = body })
        end
        if cfg.Buttons then
            local brow = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30),
                LayoutOrder = 3, Parent = body })
            List(brow, 8, Enum.FillDirection.Horizontal)
            for _, b in ipairs(cfg.Buttons) do
                local pill = New("TextButton", { BackgroundColor3 = Theme.Elevated, Text = "",
                    Size = UDim2.new(0, 120, 1, 0), AutoButtonColor = false, Parent = brow })
                Corner(pill, 8); Stroke(pill, Theme.Accent, 1, 0.5)
                label(pill, "  " .. (b.Title or "Button"), 12, Theme.Accent, FONT_BOLD, 8)
                pill.MouseButton1Click:Connect(function() if b.Callback then pcall(b.Callback) end end)
            end
        end
        return c
    end)

    ------------------------------------------------------------------ Image
    register("Image", function(self, cfg)
        local ratio = 16 / 9
        if type(cfg.AspectRatio) == "string" then
            local a, b = cfg.AspectRatio:match("(%d+):(%d+)")
            if a then ratio = tonumber(a) / tonumber(b) end
        end
        local f = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 150),
            LayoutOrder = nextOrder(self), Parent = self.Content })
        local img = New("ImageLabel", { BackgroundColor3 = Theme.Elevated, Image = cfg.Image or "",
            ScaleType = Enum.ScaleType.Crop, Size = UDim2.new(1, 0, 1, 0), Parent = f })
        Corner(img, cfg.Radius or 10)
        New("UIAspectRatioConstraint", { AspectRatio = ratio, Parent = f })
        return f
    end)

    ------------------------------------------------------------------ Button
    register("Button", function(self, cfg)
        local c = card(self, 42)
        if cfg.Locked then c.BackgroundTransparency = 0.96 end
        local accent = cfg.Color
        if accent then
            c.BackgroundColor3 = accent; c.BackgroundTransparency = 0.12
            for _, ch in ipairs(c:GetChildren()) do if ch:IsA("UIGradient") then ch:Destroy() end end
        end
        local textColor = accent and Theme.Text or Theme.Text
        local hasIcon = cfg.Icon and cfg.Icon ~= ""
        local ix = 14
        if hasIcon then makeIcon(c, cfg.Icon, 18, accent and Theme.Text or Theme.Accent).Position = UDim2.new(0, 14, 0.5, -9); ix = 40 end
        local title = New("TextLabel", { BackgroundTransparency = 1, Text = cfg.Title or "Button",
            Font = FONT_MED, TextSize = 14, TextColor3 = textColor,
            TextXAlignment = (cfg.Justify == "Center") and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            Position = UDim2.new(0, cfg.Justify == "Center" and 0 or ix, 0, cfg.Desc and -8 or 0),
            Size = UDim2.new(1, -(ix + 30), cfg.Desc and 0 or 1, cfg.Desc and 30 or 0), Parent = c })
        if cfg.Desc then
            c.Size = UDim2.new(1, 0, 0, 54)
            title.Position = UDim2.new(0, ix, 0, 8); title.Size = UDim2.new(1, -(ix+30), 0, 18)
            label(c, cfg.Desc, 12, Theme.Muted, FONT, ix, UDim2.new(1, -(ix+30), 0, 18)).Position = UDim2.new(0, ix, 0, 28)
        end
        local arrow = New("TextLabel", { BackgroundTransparency = 1, Text = "›", Font = FONT_BOLD,
            TextSize = 20, TextColor3 = accent and Theme.Text or Theme.Accent, Position = UDim2.new(1, -26, 0.5, -11),
            Size = UDim2.new(0, 16, 0, 22), Parent = c })
        local btn = New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 1, 0), Parent = c })
        local baseT = c.BackgroundTransparency
        btn.MouseEnter:Connect(function() if not cfg.Locked then Tween(c, 0.15, { BackgroundTransparency = math.max(0, baseT - 0.06) }); Tween(arrow, 0.15, { Position = UDim2.new(1, -22, 0.5, -11) }) end end)
        btn.MouseLeave:Connect(function() Tween(c, 0.15, { BackgroundTransparency = baseT }); Tween(arrow, 0.15, { Position = UDim2.new(1, -26, 0.5, -11) }) end)
        btn.MouseButton1Click:Connect(function()
            if cfg.Locked then if self.Window then self.Window:Notify({ Title = "Locked", Content = cfg.LockedTitle or "This element is locked" }) end return end
            local flash = New("Frame", { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.6,
                Size = UDim2.new(1, 0, 1, 0), Parent = c }); Corner(flash, 10)
            Tween(flash, 0.35, { BackgroundTransparency = 1 }).Completed:Connect(function() flash:Destroy() end)
            if cfg.Callback then pcall(cfg.Callback) end
        end)
        local obj = { Frame = c }
        function obj:Highlight()
            local s = Stroke(c, Theme.AccentSoft, 2, 0)
            Tween(s, 0.8, { Transparency = 1 }).Completed:Connect(function() s:Destroy() end)
        end
        function obj:SetTitle(t) title.Text = t end
        return obj
    end)

    ------------------------------------------------------------------ Toggle
    register("Toggle", function(self, cfg)
        local checkbox = cfg.Type == "Checkbox"
        local state = cfg.Value and true or false
        local c = card(self, cfg.Desc and 54 or 42)
        local title = label(c, cfg.Title or "Toggle", 14, Theme.Text, FONT_MED, 14, UDim2.new(1, -70, cfg.Desc and 0 or 1, cfg.Desc and 30 or 0))
        if cfg.Desc then title.Position = UDim2.new(0, 14, 0, 8); title.Size = UDim2.new(1, -70, 0, 18)
            label(c, cfg.Desc, 12, Theme.Muted, FONT, 14, UDim2.new(1, -70, 0, 18)).Position = UDim2.new(0, 14, 0, 28) end
        local track, knob, box
        if checkbox then
            box = New("Frame", { BackgroundColor3 = state and Theme.Accent or Theme.Elevated,
                Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -36, 0.5, -11), Parent = c })
            Corner(box, 6); Stroke(box, state and Theme.Accent or Theme.Muted, 1.5, 0.2)
            New("TextLabel", { Name = "chk", BackgroundTransparency = 1, Text = "✓", Font = FONT_BOLD,
                TextSize = 15, TextColor3 = Theme.Text, TextTransparency = state and 0 or 1,
                Size = UDim2.new(1, 0, 1, 0), Parent = box })
        else
            track = New("Frame", { BackgroundColor3 = state and Theme.Accent or Theme.Elevated,
                Size = UDim2.new(0, 40, 0, 22), Position = UDim2.new(1, -54, 0.5, -11), Parent = c })
            Corner(track, 11); Stroke(track, Theme.Stroke, 1, 0.85)
            knob = New("Frame", { BackgroundColor3 = Color3.fromRGB(255,255,255), Size = UDim2.new(0, 16, 0, 16),
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8), Parent = track })
            Corner(knob, 8)
        end
        local function apply(fire)
            if checkbox then
                Tween(box, 0.18, { BackgroundColor3 = state and Theme.Accent or Theme.Elevated })
                box.UIStroke.Color = state and Theme.Accent or Theme.Muted
                Tween(box.chk, 0.18, { TextTransparency = state and 0 or 1 })
            else
                Tween(track, 0.18, { BackgroundColor3 = state and Theme.Accent or Theme.Elevated })
                Tween(knob, 0.18, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) })
            end
            if fire and cfg.Callback then pcall(cfg.Callback, state) end
        end
        New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 1, 0), Parent = c })
            .MouseButton1Click:Connect(function()
                if cfg.Locked then if self.Window then self.Window:Notify({ Title = "Locked", Content = cfg.LockedTitle or "This element is locked" }) end return end
                state = not state; apply(true)
            end)
        local obj = { Frame = c, Type = "bool" }
        function obj:Set(v) state = v and true or false; apply(true) end
        function obj:Get() return state end
        if cfg.Flag and self.Window then self.Window.Flags[cfg.Flag] = obj end
        return obj
    end)

    ------------------------------------------------------------------ Slider
    register("Slider", function(self, cfg)
        local v = cfg.Value or {}
        local min, max, def = v.Min or 0, v.Max or 100, v.Default or (v.Min or 0)
        local step = cfg.Step or 1
        local value = math.clamp(def, min, max)
        local hasTitle = cfg.Title ~= nil
        local c = card(self, (cfg.Desc and 66) or (hasTitle and 54 or 40))
        local topY = 6
        if hasTitle then
            label(c, cfg.Title, 14, Theme.Text, FONT_MED, 14, UDim2.new(1, -80, 0, 18)).Position = UDim2.new(0, 14, 0, topY)
        end
        if cfg.Desc then
            label(c, cfg.Desc, 12, Theme.Muted, FONT, 14, UDim2.new(1, -80, 0, 16)).Position = UDim2.new(0, 14, 0, topY + 18)
            topY = topY + 20
        end
        local valBox
        if cfg.IsTextbox ~= false and hasTitle then
            valBox = New("TextBox", { BackgroundColor3 = Theme.Elevated, Text = tostring(value), Font = FONT_BOLD,
                TextSize = 12, TextColor3 = Theme.Accent, Size = UDim2.new(0, 52, 0, 20),
                Position = UDim2.new(1, -66, 0, topY - 1), ClearTextOnFocus = false, Parent = c })
            Corner(valBox, 6); Stroke(valBox, Theme.Stroke, 1, 0.85)
        end
        local trackY = hasTitle and (c.Size.Y.Offset - 16) or (c.Size.Y.Offset / 2 - 3)
        local fromIcon = cfg.Icons and cfg.Icons.From
        local toIcon = cfg.Icons and cfg.Icons.To
        local leftPad = fromIcon and 34 or 14
        local rightPad = toIcon and 34 or 14
        if fromIcon then makeIcon(c, fromIcon, 16, Theme.Muted).Position = UDim2.new(0, 12, 0, trackY - 5) end
        if toIcon then makeIcon(c, toIcon, 16, Theme.Muted).Position = UDim2.new(1, -28, 0, trackY - 5) end
        local track = New("Frame", { BackgroundColor3 = Theme.Elevated, Size = UDim2.new(1, -(leftPad + rightPad), 0, 6),
            Position = UDim2.new(0, leftPad, 0, trackY), Parent = c })
        Corner(track, 3); Stroke(track, Theme.Stroke, 1, 0.9)
        local fill = New("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new((value-min)/(max-min), 0, 1, 0), Parent = track })
        Corner(fill, 3); Gradient(fill, Theme.AccentSoft, Theme.Accent, 0)
        local knob = New("Frame", { BackgroundColor3 = Color3.fromRGB(255,255,255), Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new((value-min)/(max-min), -7, 0.5, -7), Parent = track }); Corner(knob, 7); Shadow(knob, 10, 0.5)
        local tip
        if cfg.IsTooltip then
            tip = New("TextLabel", { BackgroundColor3 = Theme.AccentDeep, Text = tostring(value), Font = FONT_BOLD,
                TextSize = 11, TextColor3 = Theme.Text, Size = UDim2.new(0, 34, 0, 18),
                Position = UDim2.new((value-min)/(max-min), -17, 0, -24), Parent = track }); Corner(tip, 5)
        end
        local dragging = false
        local function set(px, fire)
            local rel = math.clamp((px - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
            value = min + math.floor(((max - min) * rel) / step + 0.5) * step
            value = math.clamp(value, min, max)
            local nr = (value - min) / (max - min)
            fill.Size = UDim2.new(nr, 0, 1, 0); knob.Position = UDim2.new(nr, -7, 0.5, -7)
            if valBox then valBox.Text = tostring(value) end
            if tip then tip.Text = tostring(value); tip.Position = UDim2.new(nr, -17, 0, -24) end
            if fire ~= false and cfg.Callback then pcall(cfg.Callback, value) end
        end
        local hit = New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 0, 24),
            Position = UDim2.new(0, 0, 0, trackY - 10), Parent = c })
        hit.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; set(i.Position.X) end end)
        hit.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
        UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then set(i.Position.X) end end)
        if valBox then valBox.FocusLost:Connect(function()
            local n = tonumber(valBox.Text)
            if n then value = math.clamp(n, min, max); local nr = (value-min)/(max-min)
                fill.Size = UDim2.new(nr,0,1,0); knob.Position = UDim2.new(nr,-7,0.5,-7); valBox.Text = tostring(value)
                if cfg.Callback then pcall(cfg.Callback, value) end
            else valBox.Text = tostring(value) end
        end) end
        local obj = { Frame = c, Type = "number" }
        function obj:Set(n) set(track.AbsolutePosition.X + (math.clamp(n,min,max)-min)/(max-min)*track.AbsoluteSize.X) end
        function obj:Get() return value end
        if cfg.Flag and self.Window then self.Window.Flags[cfg.Flag] = obj end
        return obj
    end)

    ------------------------------------------------------------------ Input
    register("Input", function(self, cfg)
        local textarea = cfg.Type == "Textarea"
        local c = card(self, cfg.Desc and 60 or (textarea and 74 or 42))
        local ix = 14
        if cfg.Icon or cfg.InputIcon then makeIcon(c, cfg.Icon or cfg.InputIcon, 16, Theme.Accent).Position = UDim2.new(0, 14, 0, 13); ix = 38 end
        if cfg.Title then
            label(c, cfg.Title, 14, Theme.Text, FONT_MED, ix, UDim2.new(0.42, -ix, 0, cfg.Desc and 18 or (textarea and 20 or 42))).Position = UDim2.new(0, ix, 0, cfg.Desc and 8 or 0)
            if cfg.Desc then label(c, cfg.Desc, 12, Theme.Muted, FONT, ix, UDim2.new(0.42, -ix, 0, 18)).Position = UDim2.new(0, ix, 0, 28) end
        end
        local boxW = cfg.Title and UDim2.new(0.58, -14, 0, textarea and 60 or 26) or UDim2.new(1, -28, 0, textarea and 60 or 26)
        local boxX = cfg.Title and UDim2.new(0.42, 0, 0.5, 0) or UDim2.new(0, 14, 0.5, 0)
        local box = New("Frame", { BackgroundColor3 = Theme.Elevated, AnchorPoint = Vector2.new(0, 0.5),
            Position = boxX, Size = boxW, Parent = c }); Corner(box, 8); local bs = Stroke(box, Theme.Stroke, 1, 0.8)
        local tb = New("TextBox", { BackgroundTransparency = 1, Text = cfg.Value or "",
            PlaceholderText = cfg.Placeholder or "Type here…", PlaceholderColor3 = Theme.Muted,
            Font = FONT, TextSize = 13, TextColor3 = Theme.Text, ClearTextOnFocus = false,
            MultiLine = textarea, TextWrapped = textarea, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = textarea and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
            Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0), Parent = box })
        tb.Focused:Connect(function() bs.Color = Theme.Accent; bs.Transparency = 0 end)
        tb.FocusLost:Connect(function(enter) bs.Color = Theme.Stroke; bs.Transparency = 0.8
            if cfg.Callback then pcall(cfg.Callback, tb.Text) end end)
        local obj = { Frame = c, Type = "string" }
        function obj:Set(t) tb.Text = tostring(t); if cfg.Callback then pcall(cfg.Callback, tb.Text) end end
        function obj:Get() return tb.Text end
        if cfg.Flag and self.Window then self.Window.Flags[cfg.Flag] = obj end
        return obj
    end)

    ------------------------------------------------------------------ Keybind
    register("Keybind", function(self, cfg)
        local key = cfg.Value
        local listening = false
        local c = card(self, cfg.Desc and 54 or 42)
        local title = label(c, cfg.Title or "Keybind", 14, Theme.Text, FONT_MED, 14, UDim2.new(1, -100, cfg.Desc and 0 or 1, cfg.Desc and 30 or 0))
        if cfg.Desc then title.Position = UDim2.new(0, 14, 0, 8); title.Size = UDim2.new(1, -100, 0, 18)
            label(c, cfg.Desc, 12, Theme.Muted, FONT, 14, UDim2.new(1, -100, 0, 18)).Position = UDim2.new(0, 14, 0, 28) end
        local kb = New("TextButton", { BackgroundColor3 = Theme.Elevated, Text = key or "None", Font = FONT_BOLD,
            TextSize = 12, TextColor3 = Theme.Accent, Size = UDim2.new(0, 74, 0, 26),
            Position = UDim2.new(1, -88, 0.5, -13), AutoButtonColor = false, Parent = c })
        Corner(kb, 6); local ks = Stroke(kb, Theme.Stroke, 1, 0.8)
        kb.MouseButton1Click:Connect(function() listening = true; kb.Text = "…"; ks.Color = Theme.Accent; ks.Transparency = 0 end)
        UserInputService.InputBegan:Connect(function(i, gpe)
            if listening and i.UserInputType == Enum.UserInputType.Keyboard then
                key = i.KeyCode.Name; kb.Text = key; listening = false; ks.Color = Theme.Stroke; ks.Transparency = 0.8
                if cfg.Callback then pcall(cfg.Callback, key) end
            elseif not gpe and key and i.KeyCode == Enum.KeyCode[key] then
                if cfg.Callback then pcall(cfg.Callback, key) end
            end
        end)
        local obj = { Frame = c, Type = "string" }
        function obj:Set(k) key = k; kb.Text = tostring(k) end
        function obj:Get() return key end
        if cfg.Flag and self.Window then self.Window.Flags[cfg.Flag] = obj end
        return obj
    end)

    ------------------------------------------------------------------ Colorpicker
    register("Colorpicker", function(self, cfg)
        local color = cfg.Default or Color3.fromRGB(244, 114, 182)
        local h, s, val = Color3.toHSV(color)
        local c = card(self, cfg.Desc and 54 or 42)
        local title = label(c, cfg.Title or "Colorpicker", 14, Theme.Text, FONT_MED, 14, UDim2.new(1, -70, cfg.Desc and 0 or 1, cfg.Desc and 30 or 0))
        if cfg.Desc then title.Position = UDim2.new(0, 14, 0, 8); title.Size = UDim2.new(1, -70, 0, 18)
            label(c, cfg.Desc, 12, Theme.Muted, FONT, 14, UDim2.new(1, -70, 0, 18)).Position = UDim2.new(0, 14, 0, 28) end
        local swatch = New("TextButton", { BackgroundColor3 = color, Text = "", Size = UDim2.new(0, 34, 0, 22),
            Position = UDim2.new(1, -48, 0.5, -11), AutoButtonColor = false, Parent = c })
        Corner(swatch, 6); Stroke(swatch, Theme.Stroke, 1, 0.5)

        local popup = New("Frame", { BackgroundColor3 = Theme.Elevated, Visible = false, ZIndex = 40,
            Size = UDim2.new(1, -28, 0, 150), Position = UDim2.new(0, 14, 0, (c.Size.Y.Offset)), Parent = c })
        Corner(popup, 10); Stroke(popup, Theme.Accent, 1, 0.4)
        local svBox = New("ImageButton", { BackgroundColor3 = Color3.fromHSV(h, 1, 1), AutoButtonColor = false,
            Size = UDim2.new(1, -40, 1, -20), Position = UDim2.new(0, 10, 0, 10), ZIndex = 41,
            Image = "rbxassetid://4155801252", Parent = popup }); Corner(svBox, 8)  -- white->transparent overlay
        New("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://4155801252",
            Size = UDim2.new(1,0,1,0), ZIndex = 42, Parent = svBox })
        local svPick = New("Frame", { BackgroundColor3 = Color3.fromRGB(255,255,255), Size = UDim2.new(0, 10, 0, 10),
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(s, 0, 1 - val, 0), ZIndex = 43, Parent = svBox })
        Corner(svPick, 5); Stroke(svPick, Color3.fromRGB(0,0,0), 1, 0.3)
        local hueBar = New("ImageButton", { AutoButtonColor = false, Size = UDim2.new(0, 18, 1, -20),
            Position = UDim2.new(1, -28, 0, 10), ZIndex = 41, BackgroundColor3 = Color3.fromRGB(255,255,255), Parent = popup })
        Corner(hueBar, 6)
        Gradient(hueBar, Color3.fromRGB(255,0,0), Color3.fromRGB(255,0,0), 90,
            NumberSequence.new(0))
        do -- rainbow gradient
            local ug = hueBar:FindFirstChildOfClass("UIGradient")
            ug.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
                ColorSequenceKeypoint.new(0.34, Color3.fromRGB(0,255,0)),
                ColorSequenceKeypoint.new(0.51, Color3.fromRGB(0,255,255)),
                ColorSequenceKeypoint.new(0.68, Color3.fromRGB(0,0,255)),
                ColorSequenceKeypoint.new(0.85, Color3.fromRGB(255,0,255)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0)) })
        end
        local huePick = New("Frame", { BackgroundColor3 = Color3.fromRGB(255,255,255), Size = UDim2.new(1, 4, 0, 4),
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, h, 0), ZIndex = 43, Parent = hueBar })
        Corner(huePick, 2); Stroke(huePick, Color3.fromRGB(0,0,0), 1, 0.4)

        local function refresh(fire)
            color = Color3.fromHSV(h, s, val)
            swatch.BackgroundColor3 = color
            svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            svPick.Position = UDim2.new(s, 0, 1 - val, 0)
            huePick.Position = UDim2.new(0.5, 0, h, 0)
            if fire and cfg.Callback then pcall(cfg.Callback, color) end
        end
        local dragSV, dragHue = false, false
        local function updSV(px, py)
            s = math.clamp((px - svBox.AbsolutePosition.X) / math.max(1, svBox.AbsoluteSize.X), 0, 1)
            val = 1 - math.clamp((py - svBox.AbsolutePosition.Y) / math.max(1, svBox.AbsoluteSize.Y), 0, 1)
            refresh(true)
        end
        local function updHue(py)
            h = math.clamp((py - hueBar.AbsolutePosition.Y) / math.max(1, hueBar.AbsoluteSize.Y), 0, 1)
            refresh(true)
        end
        svBox.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragSV = true; updSV(i.Position.X, i.Position.Y) end end)
        hueBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragHue = true; updHue(i.Position.Y) end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragSV = false; dragHue = false end end)
        UserInputService.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                if dragSV then updSV(i.Position.X, i.Position.Y) end
                if dragHue then updHue(i.Position.Y) end
            end
        end)
        local open = false
        swatch.MouseButton1Click:Connect(function()
            open = not open; popup.Visible = open
            c.Size = UDim2.new(1, 0, 0, open and ((cfg.Desc and 54 or 42) + 160) or (cfg.Desc and 54 or 42))
        end)
        local obj = { Frame = c, Type = "color" }
        function obj:Set(col) h, s, val = Color3.toHSV(col); refresh(true) end
        function obj:Get() return color end
        if cfg.Flag and self.Window then self.Window.Flags[cfg.Flag] = obj end
        return obj
    end)

    ------------------------------------------------------------------ Dropdown
    register("Dropdown", function(self, cfg)
        local multi = cfg.Multi and true or false
        local values = cfg.Values or {}
        local selected = multi and (type(cfg.Value) == "table" and cfg.Value or {}) or cfg.Value
        local open = false
        local c = card(self, 42)
        c.ClipsDescendants = true
        label(c, cfg.Title or "Dropdown", 14, Theme.Text, FONT_MED, 14, UDim2.new(0.5, -14, 0, 42))
        local function displayText()
            if multi then
                local t = {}
                for k, on in pairs(selected) do if on == true then table.insert(t, tostring(k)) elseif type(k) == "number" then table.insert(t, tostring(on)) end end
                if #t == 0 then return "None" end
                return table.concat(t, ", ")
            else
                return selected and tostring(type(selected) == "table" and (selected.Title or "…") or selected) or "…"
            end
        end
        local valLbl = New("TextLabel", { BackgroundTransparency = 1, Text = displayText(), Font = FONT,
            TextSize = 12, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -36, 0, 42), Parent = c })
        local chev = New("TextLabel", { BackgroundTransparency = 1, Text = "▾", Font = FONT_BOLD, TextSize = 12,
            TextColor3 = Theme.Muted, Position = UDim2.new(1, -24, 0, 0), Size = UDim2.new(0, 16, 0, 42), Parent = c })
        local listWrap = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent, Position = UDim2.new(0, 8, 0, 42), Size = UDim2.new(1, -16, 0, 0),
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = c })
        List(listWrap, 3); Pad(listWrap, 0, 0, 0, 6)

        local rowObjs = {}
        local function selText(entry, entryKey)
            if multi then return selected[entryKey] == true or selected[entry] == true end
            if type(selected) == "table" then return selected == entry end
            return selected == entry or (type(entry) == "table" and selected == entry.Title)
        end
        local function rebuild()
            for _, r in ipairs(rowObjs) do r:Destroy() end
            rowObjs = {}
            for idx, entry in ipairs(values) do
                if type(entry) == "table" and entry.Type == "Divider" then
                    local d = New("Frame", { BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.8,
                        Size = UDim2.new(1, 0, 0, 1), Parent = listWrap }); table.insert(rowObjs, d)
                else
                    local isTbl = type(entry) == "table"
                    local ttl = isTbl and (entry.Title or "?") or tostring(entry)
                    local row = New("TextButton", { BackgroundColor3 = Theme.Elevated, Text = "",
                        Size = UDim2.new(1, 0, 0, isTbl and entry.Desc and 40 or 28), AutoButtonColor = false, Parent = listWrap })
                    Corner(row, 6)
                    local tx = 10
                    if isTbl and entry.Icon then makeIcon(row, entry.Icon, 16, Theme.SubText).Position = UDim2.new(0, 8, 0, isTbl and entry.Desc and 6 or 6); tx = 32 end
                    local sel = selText(entry, ttl)
                    local nameLbl = New("TextLabel", { BackgroundTransparency = 1, Text = ttl, Font = FONT_MED, TextSize = 13,
                        TextColor3 = sel and Theme.Accent or Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left,
                        Position = UDim2.new(0, tx, 0, isTbl and entry.Desc and 4 or 0), Size = UDim2.new(1, -tx - 24, 0, isTbl and entry.Desc and 16 or 28), Parent = row })
                    if isTbl and entry.Desc then
                        New("TextLabel", { BackgroundTransparency = 1, Text = entry.Desc, Font = FONT, TextSize = 11,
                            TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Left,
                            Position = UDim2.new(0, tx, 0, 20), Size = UDim2.new(1, -tx - 24, 0, 14), Parent = row })
                    end
                    local tick = New("TextLabel", { BackgroundTransparency = 1, Text = sel and "✓" or "", Font = FONT_BOLD,
                        TextSize = 14, TextColor3 = Theme.Accent, Position = UDim2.new(1, -22, 0, 0), Size = UDim2.new(0, 16, 1, 0), Parent = row })
                    if isTbl and entry.Locked then row.BackgroundTransparency = 0.7; nameLbl.TextColor3 = Theme.Muted end
                    row.MouseButton1Click:Connect(function()
                        if isTbl and entry.Locked then return end
                        if multi then
                            selected[ttl] = not selected[ttl]
                            if isTbl and entry.Callback and selected[ttl] then pcall(entry.Callback) end
                        else
                            selected = isTbl and entry or entry
                            if isTbl and entry.Callback then pcall(entry.Callback) end
                            open = false; c.Size = UDim2.new(1, 0, 0, 42); listWrap.Size = UDim2.new(1, -16, 0, 0); Tween(chev, 0.2, { Rotation = 0 })
                        end
                        valLbl.Text = displayText()
                        rebuild()
                        if cfg.Callback then pcall(cfg.Callback, multi and selected or (isTbl and entry or entry)) end
                    end)
                    table.insert(rowObjs, row)
                end
            end
        end
        rebuild()
        New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 0, 42), Parent = c })
            .MouseButton1Click:Connect(function()
                open = not open
                local count = 0
                for _, e in ipairs(values) do count = count + ((type(e)=="table" and e.Desc) and 40 or (type(e)=="table" and e.Type=="Divider") and 5 or 28) + 3 end
                local listH = math.min(count, 160)
                listWrap.Size = UDim2.new(1, -16, 0, open and listH or 0)
                c.Size = UDim2.new(1, 0, 0, open and (42 + listH + 6) or 42)
                Tween(chev, 0.2, { Rotation = open and 180 or 0 })
            end)
        local obj = { Frame = c, Type = multi and "table" or "string" }
        function obj:Refresh(newValues) values = newValues or {}; rebuild() end
        function obj:Select(list)
            if multi then selected = {}; for _, name in ipairs(list) do selected[name] = true end
            else selected = list[1] or list end
            valLbl.Text = displayText(); rebuild()
            if cfg.Callback then pcall(cfg.Callback, multi and selected or selected) end
        end
        function obj:Set(v) if multi then obj:Select(type(v)=="table" and v or {v}) else selected = v; valLbl.Text = displayText(); rebuild() end end
        function obj:Get() return multi and selected or selected end
        if cfg.Flag and self.Window then self.Window.Flags[cfg.Flag] = obj end
        return obj
    end)

    --==================================================================
    -- NOTIFY  &  POPUP  (attached per ScreenGui)
    --==================================================================
    local function makeNotifyHolder(sg)
        return New("Frame", { Name = "Toasts", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 300, 1, -32), ZIndex = 60, Parent = sg },
            { New("UIListLayout", { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder }) })
    end

    --==================================================================
    -- CONFIG MANAGER
    --==================================================================
    local function makeConfigManager(window)
        local folder = "LunarUI/" .. (window.Folder or "default")
        if hasFiles then safeMakeFolder("LunarUI"); safeMakeFolder(folder) end
        local CM = {}
        function CM:AllConfigs()
            local out = {}
            for _, f in ipairs(safeList(folder)) do
                local name = tostring(f):match("([^/\\]+)%.json$")
                if name then table.insert(out, name) end
            end
            return out
        end
        local function Config(name)
            local path = folder .. "/" .. name .. ".json"
            local cfg = {}
            function cfg:Save()
                if not hasFiles then return false end
                local data = {}
                for flag, obj in pairs(window.Flags) do data[flag] = serialize(obj:Get()) end
                local ok, enc = pcall(function() return HttpService:JSONEncode(data) end)
                if ok then return safeWrite(path, enc) end
                return false
            end
            function cfg:Load()
                if not hasFiles then return false end
                local raw = safeRead(path); if not raw then return false end
                local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
                if not ok then return false end
                for flag, val in pairs(data) do
                    local obj = window.Flags[flag]
                    if obj then pcall(function() obj:Set(deserialize(val)) end) end
                end
                return true
            end
            return cfg
        end
        CM.Config = function(_, name) return Config(name) end
        CM.CreateConfig = function(_, name) return Config(name) end
        CM.GetConfig = function(_, name) return Config(name) end
        CM.GetAutoLoadConfigs = function() return "{}" end
        return CM
    end

    --==================================================================
    -- WINDOW
    --==================================================================
    function Lunar:CreateWindow(cfg)
        cfg = cfg or {}
        if cfg.Theme and Lunar.Themes[cfg.Theme] then Theme = Lunar.Themes[cfg.Theme] end
        local sizeX = cfg.Size and cfg.Size.X.Offset or 660
        local sizeY = cfg.Size and cfg.Size.Y.Offset or 470

        local parent = guiParent()
        local existing = parent:FindFirstChild("LunarUI")
        if existing then existing:Destroy() end
        local ScreenGui = New("ScreenGui", { Name = "LunarUI", ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = parent })
        protect(ScreenGui)
        local Toasts = makeNotifyHolder(ScreenGui)

        local Window = {}
        Window.Flags = {}
        Window.Folder = cfg.Folder or "default"
        Window.HidePanelBackground = false

        -- root
        local root = New("Frame", { Name = "Window", BackgroundColor3 = Theme.Window, BackgroundTransparency = 0.04,
            Size = UDim2.new(0, sizeX, 0, sizeY), Position = UDim2.new(0.5, -sizeX/2, 0.5, -sizeY/2),
            ClipsDescendants = true, Parent = ScreenGui })
        Corner(root, 16); Shadow(root, 64, 0.35)
        Gradient(root, Theme.WindowGlow, Theme.Window, 35)
        local rootStroke = Stroke(root, Theme.Accent, 1.3, 0.45)
        do local sg = New("UIGradient", { Color = ColorSequence.new(Theme.AccentSoft),
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3),
                NumberSequenceKeypoint.new(0.5, 0.8), NumberSequenceKeypoint.new(1, 0.5) }), Rotation = 90, Parent = rootStroke }) end
        New("UIScale", { Name = "Scale", Parent = root })
        root.Size = UDim2.new(0, 0, 0, 0)
        Tween(root, 0.42, { Size = UDim2.new(0, sizeX, 0, sizeY) }, Enum.EasingStyle.Back)

        -- sidebar
        local sideW = 186
        local Sidebar = New("Frame", { BackgroundColor3 = Theme.Sidebar, BackgroundTransparency = 0.15,
            Size = UDim2.new(0, sideW, 1, 0), Parent = root })
        Glass(Sidebar, Theme.Glass, 0.97)
        New("Frame", { BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.9, Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(1, -1, 0, 0), Parent = Sidebar })

        -- logo
        local logoBox = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 92), Parent = Sidebar })
        makeIcon(logoBox, cfg.Icon or "moon", 40, Theme.Accent).Position = UDim2.new(0, 16, 0, 26)
        local ttl = New("TextLabel", { BackgroundTransparency = 1, Text = cfg.Title or "LUNAR HUB", Font = FONT_BOLD,
            TextSize = 18, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.new(0, 64, 0, 24), Size = UDim2.new(1, -74, 0, 22), Parent = logoBox })
        Gradient(ttl, Theme.AccentSoft, Theme.Accent, 0)
        if cfg.Author then New("TextLabel", { BackgroundTransparency = 1, Text = cfg.Author, Font = FONT, TextSize = 11,
            TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 64, 0, 48),
            Size = UDim2.new(1, -74, 0, 16), Parent = logoBox }) end

        -- search
        local searchText = ""
        local searchBox
        if cfg.HideSearchBar ~= true then
            local sb = New("Frame", { BackgroundColor3 = Theme.Elevated, BackgroundTransparency = 0.2,
                Size = UDim2.new(1, -24, 0, 30), Position = UDim2.new(0, 12, 0, 92), Parent = Sidebar })
            Corner(sb, 8); Stroke(sb, Theme.Stroke, 1, 0.85)
            makeIcon(sb, "search", 14, Theme.Muted).Position = UDim2.new(0, 8, 0.5, -7)
            searchBox = New("TextBox", { BackgroundTransparency = 1, Text = "", PlaceholderText = "Search…",
                PlaceholderColor3 = Theme.Muted, Font = FONT, TextSize = 12, TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
                Position = UDim2.new(0, 28, 0, 0), Size = UDim2.new(1, -34, 1, 0), Parent = sb })
        end

        -- tab list
        local tabsTop = (cfg.HideSearchBar ~= true) and 130 or 100
        local TabList = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
            Position = UDim2.new(0, 0, 0, tabsTop), Size = UDim2.new(1, 0, 1, -tabsTop - 12),
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = Sidebar })
        List(TabList, 4); Pad(TabList, 12, 2, 12, 8)

        -- topbar
        local topH = (cfg.Topbar and cfg.Topbar.Height) or 46
        local Content = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, sideW, 0, 0),
            Size = UDim2.new(1, -sideW, 1, 0), Parent = root })
        local Topbar = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, topH), Parent = Content })
        draggable(Topbar, root)
        local tagHolder = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 0),
            Size = UDim2.new(1, -160, 1, 0), Parent = Topbar })
        List(tagHolder, 6, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
        local macStyle = cfg.Topbar and cfg.Topbar.ButtonsType == "Mac"
        local ctrlHolder = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0, 120, 0, 28), Parent = Topbar })
        List(ctrlHolder, 8, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
        ctrlHolder:FindFirstChildOfClass("UIListLayout").HorizontalAlignment = Enum.HorizontalAlignment.Right
        local function ctrl(icon, col, cb)
            local b = New("TextButton", { BackgroundColor3 = macStyle and col or Theme.Elevated, Text = "",
                Size = UDim2.new(0, macStyle and 14 or 28, 0, macStyle and 14 or 28), AutoButtonColor = false, Parent = ctrlHolder })
            Corner(b, macStyle and 7 or 8)
            if not macStyle then makeIcon(b, icon, 15, col).Position = UDim2.new(0.5, -7, 0.5, -7); Stroke(b, Theme.Stroke, 1, 0.85) end
            b.MouseButton1Click:Connect(cb)
            return b
        end

        -- body / pages
        local Body = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, topH),
            Size = UDim2.new(1, -28, 1, -topH - 12), Parent = Content })

        -- ── Window methods
        local tabs, tabButtons, current = {}, {}, 0
        function Window:_select(i)
            for k, pg in ipairs(tabs) do pg.Visible = (k == i) end
            for k, d in ipairs(tabButtons) do
                local on = (k == i)
                Tween(d.frame, 0.2, { BackgroundColor3 = on and Theme.Accent or Theme.Sidebar,
                    BackgroundTransparency = on and 0.05 or 1 })
                d.grad.Enabled = on
                d.stroke.Transparency = on and 0.2 or 1
                Tween(d.title, 0.2, { TextColor3 = on and Theme.Text or Theme.SubText })
                Tween(d.icon, 0.2, { ImageColor3 = on and Theme.Text or Theme.Muted, TextColor3 = on and Theme.Text or Theme.Muted })
            end
            current = i
        end

        local function addTabButton(title, icon, iconColor)
            local i = #tabs + 1
            local frame = New("Frame", { BackgroundColor3 = Theme.Sidebar, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 40), LayoutOrder = i, Parent = TabList })
            Corner(frame, 10)
            local grad = Gradient(frame, Theme.Accent, Theme.AccentDeep, 20); grad.Enabled = false
            local strk = Stroke(frame, Theme.AccentSoft, 1.2, 1)
            local ic = makeIcon(frame, icon or "•", 18, iconColor or Theme.Muted); ic.Position = UDim2.new(0, 12, 0.5, -9)
            local tl = New("TextLabel", { BackgroundTransparency = 1, Text = title, Font = FONT_BOLD, TextSize = 13.5,
                TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2.new(0, 42, 0, 0), Size = UDim2.new(1, -50, 1, 0), Parent = frame })
            local btn = New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 1, 0), Parent = frame })
            btn.MouseButton1Click:Connect(function() Window:_select(i) end)
            btn.MouseEnter:Connect(function() if current ~= i then Tween(frame, 0.15, { BackgroundTransparency = 0.9 }) end end)
            btn.MouseLeave:Connect(function() if current ~= i then Tween(frame, 0.15, { BackgroundTransparency = 1 }) end end)
            tabButtons[i] = { frame = frame, grad = grad, stroke = strk, icon = ic, title = tl, name = title }

            local page = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
                ScrollBarImageColor3 = Theme.Accent, ScrollBarImageTransparency = 0.4, Size = UDim2.new(1, 0, 1, 0),
                CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = Body })
            List(page, 8); Pad(page, 2, 2, 8, 10)
            tabs[i] = page
            if i == 1 then Window:_select(1) end
            return makeContainer(Window, page), i
        end

        function Window:Tab(tcfg)
            tcfg = tcfg or {}
            local container = addTabButton(tcfg.Title or "Tab", tcfg.Icon, tcfg.IconColor)
            return container
        end

        function Window:Section(scfg)
            scfg = scfg or {}
            New("TextLabel", { BackgroundTransparency = 1, Text = (scfg.Title or "SECTION"):upper(), Font = FONT_BOLD,
                TextSize = 11, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -8, 0, 24), LayoutOrder = #tabs + 100, Parent = TabList },
                { New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 6) }) })
            local sec = {}
            function sec:Tab(tcfg) return Window:Tab(tcfg) end
            return sec
        end

        function Window:Tag(gcfg)
            gcfg = gcfg or {}
            local tag = New("Frame", { BackgroundColor3 = gcfg.Color or Theme.Elevated, Size = UDim2.new(0, 10, 0, 22),
                AutomaticSize = Enum.AutomaticSize.X, Parent = tagHolder }); Corner(tag, 6)
            if gcfg.Border then Stroke(tag, Theme.Stroke, 1, 0.7) end
            local row = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X, Parent = tag })
            List(row, 4, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
            Pad(row, 8, 0, 8, 0)
            if gcfg.Icon then makeIcon(row, gcfg.Icon, 13, Theme.Text) end
            New("TextLabel", { BackgroundTransparency = 1, Text = gcfg.Title or "tag", Font = FONT_MED, TextSize = 12,
                TextColor3 = Theme.Text, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), Parent = row })
            return tag
        end

        function Window:Notify(ncfg)
            ncfg = ncfg or {}
            local toast = New("Frame", { BackgroundColor3 = Theme.Elevated, Size = UDim2.new(1, 0, 0, 58),
                AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(1, 20, 0, 0), ZIndex = 61, Parent = Toasts })
            Corner(toast, 12); Glass(toast, Theme.Glass, 0.9); Stroke(toast, Theme.Accent, 1.2, 0.4); Shadow(toast, 30, 0.45)
            New("Frame", { BackgroundColor3 = ncfg.Color or Theme.Accent, Size = UDim2.new(0, 4, 1, -16),
                Position = UDim2.new(0, 8, 0, 8), ZIndex = 62, Parent = toast }, { New("UICorner", { CornerRadius = UDim.new(0, 2) }) })
            local tx = 20
            if ncfg.Icon then makeIcon(toast, ncfg.Icon, 18, Theme.Accent).Position = UDim2.new(0, 20, 0, 12); tx = 44 end
            New("TextLabel", { BackgroundTransparency = 1, Text = ncfg.Title or "Notice", Font = FONT_BOLD, TextSize = 14,
                TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 62,
                Position = UDim2.new(0, tx, 0, 10), Size = UDim2.new(1, -tx - 12, 0, 18), Parent = toast })
            New("TextLabel", { BackgroundTransparency = 1, Text = ncfg.Content or ncfg.Desc or "", Font = FONT, TextSize = 12,
                TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 62,
                Position = UDim2.new(0, tx, 0, 28), Size = UDim2.new(1, -tx - 12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = toast })
            Tween(toast, 0.35, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)
            task.delay(ncfg.Duration or 4, function()
                Tween(toast, 0.3, { Position = UDim2.new(1, 20, 0, 0) }).Completed:Connect(function() toast:Destroy() end)
            end)
        end

        function Window:Popup(pcfg)
            pcfg = pcfg or {}
            local dim = New("Frame", { BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0), ZIndex = 80, Parent = ScreenGui })
            Tween(dim, 0.25, { BackgroundTransparency = 0.45 })
            local box = New("Frame", { BackgroundColor3 = Theme.Window, Size = UDim2.new(0, 340, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0.5, -170, 0.5, -80), ZIndex = 81, Parent = dim })
            Corner(box, 14); Glass(box, Theme.Glass, 0.92); Stroke(box, Theme.Accent, 1.3, 0.4); Shadow(box, 50, 0.4)
            local col = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 82, Parent = box }); List(col, 10); Pad(col, 18, 18, 18, 18)
            if pcfg.Icon then makeIcon(col, pcfg.Icon, 30, Theme.Accent).LayoutOrder = 1 end
            New("TextLabel", { BackgroundTransparency = 1, Text = pcfg.Title or "Popup", Font = FONT_BOLD, TextSize = 18,
                TextColor3 = Theme.Text, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 2, ZIndex = 82, Parent = col })
            New("TextLabel", { BackgroundTransparency = 1, Text = pcfg.Content or "", Font = FONT, TextSize = 13,
                TextColor3 = Theme.SubText, TextWrapped = true, Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, ZIndex = 82, Parent = col })
            local obj = {}
            function obj:Close() Tween(box, 0.2, { Size = UDim2.new(0, 340, 0, 0) }); Tween(dim, 0.2, { BackgroundTransparency = 1 }).Completed:Connect(function() dim:Destroy() end) end
            if pcfg.Buttons then
                local brow = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 4, ZIndex = 82, Parent = col })
                List(brow, 8, Enum.FillDirection.Horizontal).HorizontalAlignment = Enum.HorizontalAlignment.Center
                for _, b in ipairs(pcfg.Buttons) do
                    local variant = b.Variant or "Primary"
                    local bb = New("TextButton", { BackgroundColor3 = variant == "Primary" and Theme.Accent or Theme.Elevated,
                        Text = "", Size = UDim2.new(0, 100, 1, 0), AutoButtonColor = false, ZIndex = 82, Parent = brow })
                    Corner(bb, 8); if variant ~= "Primary" then Stroke(bb, Theme.Stroke, 1, 0.7) end
                    New("TextLabel", { BackgroundTransparency = 1, Text = b.Title or "OK", Font = FONT_BOLD, TextSize = 13,
                        TextColor3 = Theme.Text, Size = UDim2.new(1, 0, 1, 0), ZIndex = 83, Parent = bb })
                    bb.MouseButton1Click:Connect(function() if b.Callback then pcall(b.Callback) end obj:Close() end)
                end
            end
            return obj
        end

        function Window:Destroy()
            Tween(root, 0.3, { Size = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.In).Completed:Connect(function()
                ScreenGui:Destroy()
            end)
        end
        function Window:SetUIScale(n) root.Scale.Scale = n end
        function Window:SetPanelBackground(on) Window.HidePanelBackground = not on; Sidebar.BackgroundTransparency = on and 0.15 or 1 end
        function Window:SetToggleKey(k) Window._toggleKey = k end

        -- topbar controls
        if macStyle then
            ctrl("", Theme.Success, function() end)      -- (green) placeholder
            ctrl("", Theme.Warning, function()           -- (yellow) minimize
                root.Visible = false; Window._hidden = true; if Window._openBtn then Window._openBtn.Parent.Visible = true end end)
            ctrl("", Theme.Danger, function() Window:Destroy() end) -- (red) close
        else
            ctrl("settings", Theme.SubText, function() end)
            ctrl("minus", Theme.SubText, function() root.Visible = false; Window._hidden = true; if Window._openBtn then Window._openBtn.Parent.Visible = true end end)
            Lunar.Icons["minus"] = "—"
            ctrl("x", Theme.Danger, function() Window:Destroy() end)
            Lunar.Icons["x"] = "✕"
        end

        -- open button
        do
            local ob = cfg.OpenButton or {}
            if ob.Enabled ~= false then
                local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 150, 0, 40),
                    Position = UDim2.new(0, 20, 0, 20), Visible = false, Parent = ScreenGui })
                local btn = New("TextButton", { BackgroundColor3 = Theme.Accent, Text = "", Size = UDim2.new(1, 0, 1, 0),
                    AutoButtonColor = false, Parent = holder })
                Corner(btn, (ob.CornerRadius and ob.CornerRadius.Offset) or 12)
                if ob.CornerRadius and ob.CornerRadius.Scale == 1 then btn.UICorner.CornerRadius = UDim.new(1, 0) end
                if ob.StrokeThickness then Stroke(btn, Theme.AccentSoft, ob.StrokeThickness, 0.2) end
                Shadow(btn, 26, 0.4)
                makeIcon(btn, cfg.Icon or "moon", 18, Theme.Text).Position = UDim2.new(0, 12, 0.5, -9)
                New("TextLabel", { BackgroundTransparency = 1, Text = ob.Title or "Open", Font = FONT_BOLD, TextSize = 13,
                    TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 38, 0, 0),
                    Size = UDim2.new(1, -46, 1, 0), Parent = btn })
                if ob.Draggable ~= false then draggable(btn, holder) end
                btn.MouseButton1Click:Connect(function() root.Visible = true; Window._hidden = false; holder.Visible = false end)
                Window._openBtn = btn
            end
        end

        -- toggle key
        if cfg.ToggleKey then Window._toggleKey = cfg.ToggleKey end
        UserInputService.InputBegan:Connect(function(i, gpe)
            if gpe then return end
            if Window._toggleKey and i.KeyCode == (type(Window._toggleKey) == "string" and Enum.KeyCode[Window._toggleKey] or Window._toggleKey) then
                root.Visible = not root.Visible
            end
        end)

        -- search filtering
        if searchBox then
            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local q = searchBox.Text:lower()
                for _, d in ipairs(tabButtons) do
                    d.frame.Visible = q == "" or tostring(d.name):lower():find(q, 1, true) ~= nil
                end
            end)
        end

        Window.ConfigManager = makeConfigManager(Window)
        Window.ScreenGui = ScreenGui
        Window.Root = root
        Window.Theme = Theme
        return Window
    end

    -- expose a couple of niceties on the library
    Lunar.Creator = { AddIcons = function(_, ...) return Lunar:AddIcons(...) end }
    function Lunar:Notify(t) -- global notify (uses SetCore fallback if no window)
        pcall(function() StarterGui:SetCore("SendNotification", { Title = t.Title or "Lunar", Text = t.Content or t.Text or "", Duration = t.Duration or 3 }) end)
    end
end

--══════════════════════════════════════════════════════════════════════
--  DEMO  —  builds "Lunar Hub" (delete this block to use as a library)
--══════════════════════════════════════════════════════════════════════
if not _G.__LUNAR_NO_DEMO then
    local Window = Lunar:CreateWindow({
        Title = "LUNAR HUB",
        Author = "clean glass • pink",
        Folder = "LunarHub",
        Icon = "moon",
        Theme = "Sakura",
        HideSearchBar = false,
        Topbar = { Height = 46, ButtonsType = "Mac" },
        OpenButton = { Title = "Open Lunar Hub", Enabled = true, Draggable = true, CornerRadius = UDim.new(1, 0), StrokeThickness = 2 },
        ToggleKey = "RightShift",
    })

    Window:Tag({ Title = "v" .. Lunar.Version, Icon = "github", Border = true })
    Window:Tag({ Title = "Premium", Icon = "crown", Color = Color3.fromRGB(170, 58, 128) })

    -- HOME
    local Home = Window:Tab({ Title = "Main", Icon = "home" })
    Home:Section({ Title = "Welcome to Lunar Hub", TextSize = 20 })
    Home:Paragraph({
        Title = "Clean glass. Clean pink.",
        Desc = "A fully custom, self-contained UI library. Add unlimited tabs and elements — everything auto-matches the pink glass theme. Register your own components with Lunar:AddElement and they bend right into the UI.",
        Image = "crown", ImageSize = 40,
    })
    Home:Space()
    local grp = Home:Group()
    grp:Button({ Title = "Join Discord", Justify = "Center", Icon = "discord", Color = Color3.fromRGB(88, 101, 242),
        Callback = function() if setclipboard then pcall(setclipboard, "discord.gg/lunarhub") end Window:Notify({ Title = "Copied", Content = "Discord invite copied!", Icon = "discord" }) end })
    grp:Button({ Title = "Upgrade", Justify = "Center", Icon = "crown", Color = Color3.fromRGB(170, 58, 128),
        Callback = function() Window:Notify({ Title = "Premium", Content = "You already have Premium 💖", Color = Window.Theme.Success }) end })

    -- ELEMENTS section
    local Elements = Window:Section({ Title = "Elements" })

    local Overview = Elements:Tab({ Title = "Overview", Icon = "info-square" })
    local box = Overview:Section({ Title = "Group inside a box", Box = true, BoxBorder = true, Opened = true })
    box:Toggle({ Title = "Enable Feature", Desc = "A boxed toggle", Callback = function(v) print("feature", v) end })
    box:Slider({ Title = "Intensity", Value = { Min = 0, Max = 100, Default = 50 }, Callback = function(v) print(v) end })
    Overview:Space()
    Overview:Colorpicker({ Title = "Accent Color", Default = Color3.fromRGB(244, 114, 182), Callback = function(c) print(c) end })

    local Controls = Elements:Tab({ Title = "Controls", Icon = "cursor-square" })
    local hl
    hl = Controls:Button({ Title = "Highlight me", Icon = "mouse", Callback = function() hl:Highlight() end })
    Controls:Toggle({ Title = "Toggle", Desc = "Switch style" })
    Controls:Toggle({ Title = "Checkbox", Type = "Checkbox" })
    Controls:Input({ Title = "Name", Placeholder = "Enter your name…", Icon = "user", Callback = function(t) print(t) end })
    Controls:Input({ Title = "Notes", Type = "Textarea", Placeholder = "Write here…" })
    Controls:Keybind({ Title = "Toggle UI", Value = "RightShift", Callback = function(k) Window:SetToggleKey(k) end })

    local Lists = Elements:Tab({ Title = "Lists", Icon = "dropdown" })
    Lists:Dropdown({ Title = "Single", Values = { "Sakura", "Midnight", "Aurora" }, Value = "Sakura",
        Callback = function(v) print("theme:", v) end })
    Lists:Dropdown({ Title = "Multi", Multi = true, Values = { "ESP", "Aimbot", "Fly", "Speed" }, Value = { "ESP" },
        Callback = function(t) end })
    Lists:Dropdown({ Title = "Advanced", Values = {
        { Title = "New file", Desc = "Create a new file", Icon = "file-plus", Callback = function() print("new") end },
        { Type = "Divider" },
        { Title = "Delete", Desc = "Remove it", Icon = "trash", Callback = function() print("del") end },
    } })

    -- CONFIG section
    local ConfigSec = Window:Section({ Title = "Config" })
    local ConfigTab = ConfigSec:Tab({ Title = "Config", Icon = "folder-with-files" })
    ConfigTab:Toggle({ Flag = "demoToggle", Title = "Saved Toggle", Value = false, Callback = function() end })
    ConfigTab:Slider({ Flag = "demoSlider", Title = "Saved Slider", Value = { Min = 0, Max = 100, Default = 30 }, Callback = function() end })
    ConfigTab:Colorpicker({ Flag = "demoColor", Title = "Saved Color", Default = Color3.fromRGB(244,114,182), Callback = function() end })
    local nameInput = ConfigTab:Input({ Title = "Config Name", Value = "default", Icon = "file-cog" })
    ConfigTab:Button({ Title = "Save Config", Justify = "Center", Icon = "download", Callback = function()
        local ok = Window.ConfigManager:Config(nameInput:Get()):Save()
        Window:Notify({ Title = ok and "Saved" or "Unavailable", Content = ok and "Config saved!" or "File API not supported", Icon = "check" })
    end })
    ConfigTab:Button({ Title = "Load Config", Justify = "Center", Icon = "refresh-cw", Callback = function()
        local ok = Window.ConfigManager:Config(nameInput:Get()):Load()
        Window:Notify({ Title = ok and "Loaded" or "Not found", Content = ok and "Config loaded!" or "No saved config", Icon = "refresh-cw" })
    end })

    -- ⭐ CUSTOM ELEMENT DEMO — register once, use anywhere, auto-themed.
    Lunar:AddElement("Stat", function(container, cfg, window)
        local B = Lunar.Build
        local c = B.New("Frame", { BackgroundColor3 = Lunar:GetTheme().Card, Size = UDim2.new(1, 0, 0, 46),
            Parent = container.Content })
        B.Corner(c, 10); B.Glass(c, nil, 0.93)
        B.Icon(c, cfg.Icon or "star", 22, Lunar:GetTheme().Accent).Position = UDim2.new(0, 14, 0.5, -11)
        B.New("TextLabel", { BackgroundTransparency = 1, Text = cfg.Title or "Stat", Font = Enum.Font.GothamMedium,
            TextSize = 14, TextColor3 = Lunar:GetTheme().Text, TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 46, 0, 0), Size = UDim2.new(1, -120, 1, 0), Parent = c })
        B.New("TextLabel", { BackgroundTransparency = 1, Text = tostring(cfg.Value or ""), Font = Enum.Font.GothamBold,
            TextSize = 15, TextColor3 = Lunar:GetTheme().Accent, TextXAlignment = Enum.TextXAlignment.Right,
            Position = UDim2.new(1, -68, 0, 0), Size = UDim2.new(0, 54, 1, 0), Parent = c })
        return { Frame = c }
    end)
    local Stats = Window:Tab({ Title = "Stats", Icon = "sparkles" })
    Stats:Section({ Title = "Custom 'Stat' element (registered via AddElement)" })
    Stats:Stat({ Title = "Developers", Value = "12,458", Icon = "users" })
    Stats:Stat({ Title = "Uptime", Value = "98.7%", Icon = "zap" })
    Stats:Stat({ Title = "Version", Value = "v" .. Lunar.Version, Icon = "rocket" })
    Stats:Stat({ Title = "Support", Value = "24/7", Icon = "globe" })

    task.delay(0.5, function()
        Window:Notify({ Title = "🌙 Lunar Hub", Content = "Loaded successfully. Enjoy the glass!", Icon = "moon", Duration = 5 })
    end)
end

return Lunar
