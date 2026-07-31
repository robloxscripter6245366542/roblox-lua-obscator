--[[
    🌙  L U N A R   H U B  🌸
    ─────────────────────────────────────────────────────────────
    A premium Roblox UI Library — self-contained, paste & run.
    Works on PC + Mobile executors (Delta / Synapse / Script-Ware / etc.)

    ▸ The MAIN tab is a full premium dashboard (recreates the concept art).
    ▸ Add your own tabs in seconds — they auto-match the pink Lunar theme.
    ▸ Ready-made components: Section, Button, Toggle, Slider, Dropdown,
      Textbox, Keybind, Paragraph, Notification.

    ── HOW TO ADD A TAB (scroll to the bottom "EXAMPLE USAGE" block) ──
        local tab = Window:AddTab("Player", "👤")
        tab:Section("Movement")
        tab:Toggle({ Text = "Infinite Jump", Default = false,
                     Callback = function(on) ... end })
        tab:Slider({ Text = "WalkSpeed", Min = 16, Max = 250,
                     Default = 16, Callback = function(v) ... end })
--]]

local Lunar = {} do
    --==================================================================
    -- SERVICES
    --==================================================================
    local Players            = game:GetService("Players")
    local UserInputService   = game:GetService("UserInputService")
    local TweenService       = game:GetService("TweenService")
    local RunService         = game:GetService("RunService")
    local StarterGui         = game:GetService("StarterGui")
    local LocalPlayer        = Players.LocalPlayer

    --==================================================================
    -- THEME  (sampled directly from the Lunar Hub concept art)
    --==================================================================
    local Theme = {
        Background   = Color3.fromRGB(13, 9, 18),
        Panel        = Color3.fromRGB(17, 11, 23),
        Sidebar      = Color3.fromRGB(15, 9, 20),
        Card         = Color3.fromRGB(26, 15, 33),
        CardHover    = Color3.fromRGB(36, 21, 46),
        Stroke       = Color3.fromRGB(64, 30, 60),
        StrokeGlow   = Color3.fromRGB(150, 52, 120),
        Accent       = Color3.fromRGB(233, 90, 178),
        AccentLight  = Color3.fromRGB(255, 143, 208),
        AccentDeep   = Color3.fromRGB(150, 38, 110),
        Text         = Color3.fromRGB(246, 233, 247),
        SubText      = Color3.fromRGB(196, 165, 200),
        Muted        = Color3.fromRGB(138, 108, 148),
        Success      = Color3.fromRGB(82, 222, 152),
        Danger       = Color3.fromRGB(244, 78, 118),
    }

    local FONT      = Enum.Font.Gotham
    local FONT_MED  = Enum.Font.GothamMedium
    local FONT_BOLD = Enum.Font.GothamBold

    --==================================================================
    -- LOW-LEVEL HELPERS
    --==================================================================
    local function New(class, props, children)
        local inst = Instance.new(class)
        if props then
            for k, v in pairs(props) do
                if k ~= "Parent" then inst[k] = v end
            end
        end
        if children then
            for _, c in ipairs(children) do c.Parent = inst end
        end
        if props and props.Parent then inst.Parent = props.Parent end
        return inst
    end

    local function Corner(parent, r)
        return New("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = parent })
    end

    local function Stroke(parent, color, thickness, transparency)
        return New("UIStroke", {
            Color = color or Theme.Stroke,
            Thickness = thickness or 1,
            Transparency = transparency or 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = parent,
        })
    end

    local function Gradient(parent, c1, c2, rotation, transparency)
        local seq = ColorSequence.new({
            ColorSequenceKeypoint.new(0, c1),
            ColorSequenceKeypoint.new(1, c2),
        })
        return New("UIGradient", {
            Color = seq,
            Rotation = rotation or 90,
            Transparency = transparency or NumberSequence.new(0),
            Parent = parent,
        })
    end

    local function Pad(parent, all, l, t, r, b)
        return New("UIPadding", {
            PaddingLeft   = UDim.new(0, l or all or 0),
            PaddingRight  = UDim.new(0, r or all or 0),
            PaddingTop    = UDim.new(0, t or all or 0),
            PaddingBottom = UDim.new(0, b or all or 0),
            Parent = parent,
        })
    end

    local function Tween(inst, time, props, style, dir)
        local ti = TweenInfo.new(time or 0.18,
            style or Enum.EasingStyle.Quad,
            dir or Enum.EasingDirection.Out)
        local t = TweenService:Create(inst, ti, props)
        t:Play()
        return t
    end

    -- soft drop-shadow (falls back silently if asset unavailable)
    local function Shadow(parent, size, transparency)
        return New("ImageLabel", {
            Name = "Shadow",
            BackgroundTransparency = 1,
            Image = "rbxassetid://5028857084",
            ImageColor3 = Color3.fromRGB(0, 0, 0),
            ImageTransparency = transparency or 0.35,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(24, 24, 276, 276),
            Size = UDim2.new(1, size or 40, 1, size or 40),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            ZIndex = 0,
            Parent = parent,
        })
    end

    --==================================================================
    -- GUI ROOT  (gethui > CoreGui > PlayerGui, with protect_gui)
    --==================================================================
    local function guiRoot()
        local ok, h = pcall(function() return gethui and gethui() end)
        if ok and h then return h end
        local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok2 and cg then return cg end
        return LocalPlayer:WaitForChild("PlayerGui")
    end

    local function notify(title, text, dur)
        pcall(function()
            StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = dur or 3 })
        end)
    end

    --==================================================================
    -- DRAG (mouse + touch)
    --==================================================================
    local function makeDraggable(handle, target)
        local dragging, startPos, startAbs
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                startPos = input.Position
                startAbs = target.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - startPos
                target.Position = UDim2.new(
                    startAbs.X.Scale, startAbs.X.Offset + delta.X,
                    startAbs.Y.Scale, startAbs.Y.Offset + delta.Y)
            end
        end)
    end

    --==================================================================
    -- NOTIFICATION SYSTEM  (custom Lunar-styled toasts)
    --==================================================================
    local notifyHolder
    local function ensureNotifyHolder(root)
        if notifyHolder and notifyHolder.Parent then return notifyHolder end
        notifyHolder = New("Frame", {
            Name = "LunarToasts",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -16, 1, -16),
            Size = UDim2.new(0, 300, 1, -32),
            Parent = root,
        }, {
            New("UIListLayout", {
                Padding = UDim.new(0, 10),
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        return notifyHolder
    end

    --==================================================================
    -- COMPONENT FACTORY  (returned per-tab so controls match the theme)
    --==================================================================
    local function buildComponents(page)
        local api = {}

        local function baseCard(height)
            local card = New("Frame", {
                BackgroundColor3 = Theme.Card,
                Size = UDim2.new(1, 0, 0, height),
                Parent = page,
            })
            Corner(card, 10)
            Stroke(card, Theme.Stroke, 1, 0.2)
            return card
        end

        function api:Section(text)
            local holder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 30),
                Parent = page,
            })
            local bar = New("Frame", {
                BackgroundColor3 = Theme.Accent,
                Size = UDim2.new(0, 3, 0, 16),
                Position = UDim2.new(0, 2, 0.5, -8),
                Parent = holder,
            })
            Corner(bar, 2)
            New("TextLabel", {
                BackgroundTransparency = 1,
                Text = text,
                Font = FONT_BOLD,
                TextSize = 15,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(1, -14, 1, 0),
                Parent = holder,
            })
            return holder
        end

        function api:Paragraph(title, body)
            local card = baseCard(60)
            local autoY = New("UITextSizeConstraint", {})
            New("TextLabel", {
                BackgroundTransparency = 1,
                Text = title,
                Font = FONT_BOLD,
                TextSize = 14,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 14, 0, 10),
                Size = UDim2.new(1, -28, 0, 18),
                Parent = card,
            })
            local b = New("TextLabel", {
                BackgroundTransparency = 1,
                Text = body,
                Font = FONT,
                TextSize = 13,
                TextColor3 = Theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                Position = UDim2.new(0, 14, 0, 30),
                Size = UDim2.new(1, -28, 1, -38),
                Parent = card,
            })
            return card
        end

        function api:Label(text)
            local lbl = New("TextLabel", {
                BackgroundTransparency = 1,
                Text = text,
                Font = FONT,
                TextSize = 13,
                TextColor3 = Theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 20),
                Parent = page,
            })
            return lbl
        end

        function api:Button(cfg)
            cfg = cfg or {}
            local card = baseCard(40)
            New("TextLabel", {
                BackgroundTransparency = 1,
                Text = cfg.Text or "Button",
                Font = FONT_MED,
                TextSize = 14,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(1, -44, 1, 0),
                Parent = card,
            })
            local arrow = New("TextLabel", {
                BackgroundTransparency = 1,
                Text = "›",
                Font = FONT_BOLD,
                TextSize = 20,
                TextColor3 = Theme.Accent,
                Position = UDim2.new(1, -28, 0, -1),
                Size = UDim2.new(0, 20, 1, 0),
                Parent = card,
            })
            local btn = New("TextButton", {
                BackgroundTransparency = 1,
                Text = "",
                Size = UDim2.new(1, 0, 1, 0),
                Parent = card,
            })
            btn.MouseEnter:Connect(function()
                Tween(card, 0.15, { BackgroundColor3 = Theme.CardHover })
                Tween(arrow, 0.15, { Position = UDim2.new(1, -24, 0, -1) })
            end)
            btn.MouseLeave:Connect(function()
                Tween(card, 0.15, { BackgroundColor3 = Theme.Card })
                Tween(arrow, 0.15, { Position = UDim2.new(1, -28, 0, -1) })
            end)
            btn.MouseButton1Click:Connect(function()
                Tween(card, 0.08, { BackgroundColor3 = Theme.Accent }).Completed:Connect(function()
                    Tween(card, 0.25, { BackgroundColor3 = Theme.Card })
                end)
                if cfg.Callback then pcall(cfg.Callback) end
            end)
            return card
        end

        function api:Toggle(cfg)
            cfg = cfg or {}
            local state = cfg.Default and true or false
            local card = baseCard(40)
            New("TextLabel", {
                BackgroundTransparency = 1,
                Text = cfg.Text or "Toggle",
                Font = FONT_MED,
                TextSize = 14,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(1, -64, 1, 0),
                Parent = card,
            })
            local track = New("Frame", {
                BackgroundColor3 = state and Theme.Accent or Theme.Stroke,
                Size = UDim2.new(0, 38, 0, 20),
                Position = UDim2.new(1, -50, 0.5, -10),
                Parent = card,
            })
            Corner(track, 10)
            local knob = New("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Size = UDim2.new(0, 14, 0, 14),
                Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
                Parent = track,
            })
            Corner(knob, 7)

            local function apply(fire)
                Tween(track, 0.18, { BackgroundColor3 = state and Theme.Accent or Theme.Stroke })
                Tween(knob, 0.18, { Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) })
                if fire and cfg.Callback then pcall(cfg.Callback, state) end
            end

            local btn = New("TextButton", {
                BackgroundTransparency = 1, Text = "",
                Size = UDim2.new(1, 0, 1, 0), Parent = card,
            })
            btn.MouseButton1Click:Connect(function() state = not state; apply(true) end)

            local obj = { Card = card }
            function obj:Set(v) state = v and true or false; apply(true) end
            function obj:Get() return state end
            return obj
        end

        function api:Slider(cfg)
            cfg = cfg or {}
            local min, max = cfg.Min or 0, cfg.Max or 100
            local value = math.clamp(cfg.Default or min, min, max)
            local card = baseCard(52)
            New("TextLabel", {
                BackgroundTransparency = 1,
                Text = cfg.Text or "Slider",
                Font = FONT_MED,
                TextSize = 14,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 14, 0, 6),
                Size = UDim2.new(1, -70, 0, 18),
                Parent = card,
            })
            local valLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Text = tostring(value),
                Font = FONT_BOLD,
                TextSize = 13,
                TextColor3 = Theme.Accent,
                TextXAlignment = Enum.TextXAlignment.Right,
                Position = UDim2.new(1, -54, 0, 6),
                Size = UDim2.new(0, 40, 0, 18),
                Parent = card,
            })
            local track = New("Frame", {
                BackgroundColor3 = Theme.Stroke,
                Size = UDim2.new(1, -28, 0, 6),
                Position = UDim2.new(0, 14, 0, 34),
                Parent = card,
            })
            Corner(track, 3)
            local fill = New("Frame", {
                BackgroundColor3 = Theme.Accent,
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                Parent = track,
            })
            Corner(fill, 3)
            Gradient(fill, Theme.AccentLight, Theme.Accent, 0)
            local knob = New("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new((value - min) / (max - min), -7, 0.5, -7),
                Parent = track,
            })
            Corner(knob, 7)

            local dragging = false
            local function setFromX(px)
                local rel = math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                value = math.floor((min + (max - min) * rel) + 0.5)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                knob.Position = UDim2.new(rel, -7, 0.5, -7)
                valLabel.Text = tostring(value)
                if cfg.Callback then pcall(cfg.Callback, value) end
            end
            local hit = New("TextButton", {
                BackgroundTransparency = 1, Text = "",
                Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 26),
                Parent = card,
            })
            hit.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = true; setFromX(i.Position.X)
                end
            end)
            hit.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
                or i.UserInputType == Enum.UserInputType.Touch) then
                    setFromX(i.Position.X)
                end
            end)

            local obj = { Card = card }
            function obj:Set(v)
                v = math.clamp(v, min, max); value = v
                local rel = (v - min) / (max - min)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                knob.Position = UDim2.new(rel, -7, 0.5, -7)
                valLabel.Text = tostring(v)
                if cfg.Callback then pcall(cfg.Callback, v) end
            end
            function obj:Get() return value end
            return obj
        end

        function api:Dropdown(cfg)
            cfg = cfg or {}
            local options = cfg.Options or {}
            local selected = cfg.Default or (options[1] or "Select")
            local open = false
            local card = baseCard(40)
            card.ClipsDescendants = true
            New("TextLabel", {
                BackgroundTransparency = 1,
                Text = cfg.Text or "Dropdown",
                Font = FONT_MED, TextSize = 14, TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0.5, -14, 0, 40),
                Parent = card,
            })
            local valLbl = New("TextLabel", {
                BackgroundTransparency = 1, Text = selected,
                Font = FONT, TextSize = 13, TextColor3 = Theme.Accent,
                TextXAlignment = Enum.TextXAlignment.Right,
                Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -34, 0, 40),
                Parent = card,
            })
            local chev = New("TextLabel", {
                BackgroundTransparency = 1, Text = "▾",
                Font = FONT_BOLD, TextSize = 12, TextColor3 = Theme.Muted,
                Position = UDim2.new(1, -24, 0, 0), Size = UDim2.new(0, 16, 0, 40),
                Parent = card,
            })
            local listHolder = New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 40),
                Size = UDim2.new(1, 0, 0, 0),
                Parent = card,
            }, {
                New("UIListLayout", { Padding = UDim.new(0, 2) }),
                New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 6) }),
            })

            local function rebuild()
                for _, c in ipairs(listHolder:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for _, opt in ipairs(options) do
                    local o = New("TextButton", {
                        BackgroundColor3 = Theme.Background,
                        Text = opt, Font = FONT, TextSize = 13,
                        TextColor3 = opt == selected and Theme.Accent or Theme.SubText,
                        Size = UDim2.new(1, 0, 0, 26),
                        AutoButtonColor = false,
                        Parent = listHolder,
                    })
                    Corner(o, 6)
                    o.MouseButton1Click:Connect(function()
                        selected = opt; valLbl.Text = opt
                        for _, c in ipairs(listHolder:GetChildren()) do
                            if c:IsA("TextButton") then
                                c.TextColor3 = c.Text == selected and Theme.Accent or Theme.SubText
                            end
                        end
                        if cfg.Callback then pcall(cfg.Callback, opt) end
                    end)
                end
            end
            rebuild()

            local function toggle()
                open = not open
                local h = open and (40 + #options * 28 + 8) or 40
                Tween(card, 0.2, { Size = UDim2.new(1, 0, 0, h) })
                Tween(chev, 0.2, { Rotation = open and 180 or 0 })
                listHolder.Size = UDim2.new(1, 0, 0, open and (#options * 28) or 0)
            end
            New("TextButton", {
                BackgroundTransparency = 1, Text = "",
                Size = UDim2.new(1, 0, 0, 40), Parent = card,
            }).MouseButton1Click:Connect(toggle)

            local obj = { Card = card }
            function obj:Set(v) selected = v; valLbl.Text = v end
            function obj:Get() return selected end
            function obj:Refresh(list) options = list; rebuild() end
            return obj
        end

        function api:Textbox(cfg)
            cfg = cfg or {}
            local card = baseCard(40)
            New("TextLabel", {
                BackgroundTransparency = 1, Text = cfg.Text or "Input",
                Font = FONT_MED, TextSize = 14, TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0.4, 0, 1, 0),
                Parent = card,
            })
            local box = New("Frame", {
                BackgroundColor3 = Theme.Background,
                Position = UDim2.new(0.4, 0, 0.5, -13),
                Size = UDim2.new(0.6, -14, 0, 26),
                Parent = card,
            })
            Corner(box, 6); Stroke(box, Theme.Stroke, 1, 0.3)
            local tb = New("TextBox", {
                BackgroundTransparency = 1,
                Text = cfg.Default or "",
                PlaceholderText = cfg.Placeholder or "Type here…",
                PlaceholderColor3 = Theme.Muted,
                Font = FONT, TextSize = 13, TextColor3 = Theme.Text,
                ClearTextOnFocus = false,
                Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0),
                Parent = box,
            })
            tb.Focused:Connect(function() Tween(box, 0.15, {}); box.UIStroke.Color = Theme.Accent end)
            tb.FocusLost:Connect(function(enter)
                box.UIStroke.Color = Theme.Stroke
                if enter and cfg.Callback then pcall(cfg.Callback, tb.Text) end
            end)
            return tb
        end

        function api:Keybind(cfg)
            cfg = cfg or {}
            local key = cfg.Default
            local listening = false
            local card = baseCard(40)
            New("TextLabel", {
                BackgroundTransparency = 1, Text = cfg.Text or "Keybind",
                Font = FONT_MED, TextSize = 14, TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -100, 1, 0),
                Parent = card,
            })
            local keyBox = New("TextButton", {
                BackgroundColor3 = Theme.Background,
                Text = key and key.Name or "None",
                Font = FONT_BOLD, TextSize = 12, TextColor3 = Theme.Accent,
                Size = UDim2.new(0, 70, 0, 26), Position = UDim2.new(1, -84, 0.5, -13),
                AutoButtonColor = false, Parent = card,
            })
            Corner(keyBox, 6); Stroke(keyBox, Theme.Stroke, 1, 0.3)
            keyBox.MouseButton1Click:Connect(function()
                listening = true; keyBox.Text = "…"
            end)
            UserInputService.InputBegan:Connect(function(input, gpe)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    key = input.KeyCode; listening = false
                    keyBox.Text = key.Name
                elseif not gpe and key and input.KeyCode == key then
                    if cfg.Callback then pcall(cfg.Callback) end
                end
            end)
            return card
        end

        return api
    end

    --==================================================================
    -- PUBLIC:  Lunar:CreateWindow(config)
    --==================================================================
    function Lunar:CreateWindow(config)
        config = config or {}
        local titleText   = config.Title    or "LUNAR HUB"
        local subtitle    = config.Subtitle or "月 の 力"
        local discord     = config.Discord  or "discord.gg/lunarhub"
        local userName    = config.User     or (LocalPlayer and LocalPlayer.DisplayName) or "Lunar User"
        local userRank    = config.Rank     or "Premium"
        local welcomeMsg  = config.Welcome  or "A premium Roblox UI Library made for developers."

        local root = guiRoot()
        -- clean up previous instance
        local old = root:FindFirstChild("LunarHub")
        if old then old:Destroy() end

        local ScreenGui = New("ScreenGui", {
            Name = "LunarHub",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset = true,
            Parent = root,
        })
        pcall(function() if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end end)

        ensureNotifyHolder(ScreenGui)

        --──────────────────────────────────────────────────────────────
        -- Main window
        --──────────────────────────────────────────────────────────────
        local Window = New("Frame", {
            Name = "Window",
            BackgroundColor3 = Theme.Background,
            Size = UDim2.new(0, 760, 0, 500),
            Position = UDim2.new(0.5, -380, 0.5, -250),
            AnchorPoint = Vector2.new(0, 0),
            ClipsDescendants = true,
            Parent = ScreenGui,
        })
        Corner(Window, 16)
        local winStroke = Stroke(Window, Theme.StrokeGlow, 1.4, 0.35)
        Shadow(Window, 60, 0.3)

        -- intro pop-in
        Window.Size = UDim2.new(0, 0, 0, 0)
        Tween(Window, 0.4, { Size = UDim2.new(0, 760, 0, 500) },
            Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        --──────────────────────────────────────────────────────────────
        -- SIDEBAR
        --──────────────────────────────────────────────────────────────
        local Sidebar = New("Frame", {
            BackgroundColor3 = Theme.Sidebar,
            Size = UDim2.new(0, 190, 1, 0),
            Parent = Window,
        })
        Stroke(Sidebar, Theme.Stroke, 1, 0.4)
        Gradient(Sidebar, Theme.Sidebar, Color3.fromRGB(24, 12, 32), 25)

        -- Logo block
        local logoBox = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 150),
            Parent = Sidebar,
        })
        New("TextLabel", {
            BackgroundTransparency = 1, Text = "🌙",
            Font = FONT_BOLD, TextSize = 46,
            Position = UDim2.new(0, 0, 0, 12), Size = UDim2.new(1, 0, 0, 56),
            Parent = logoBox,
        })
        local titleLbl = New("TextLabel", {
            BackgroundTransparency = 1, Text = titleText,
            Font = FONT_BOLD, TextSize = 26, TextColor3 = Theme.Text,
            Position = UDim2.new(0, 0, 0, 70), Size = UDim2.new(1, 0, 0, 30),
            Parent = logoBox,
        })
        Gradient(titleLbl, Theme.AccentLight, Theme.Accent, 90)
        New("TextLabel", {
            BackgroundTransparency = 1, Text = "✧  " .. subtitle .. "  ✧",
            Font = FONT_MED, TextSize = 13, TextColor3 = Theme.Accent,
            Position = UDim2.new(0, 0, 0, 104), Size = UDim2.new(1, 0, 0, 20),
            Parent = logoBox,
        })

        -- Tab button list
        local TabList = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            Size = UDim2.new(1, 0, 1, -150 - 78),
            Position = UDim2.new(0, 0, 0, 150),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = Sidebar,
        }, {
            New("UIListLayout", { Padding = UDim.new(0, 6) }),
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
                PaddingTop = UDim.new(0, 4),
            }),
        })

        -- Profile card (bottom)
        local Profile = New("Frame", {
            BackgroundColor3 = Theme.Card,
            Size = UDim2.new(1, -20, 0, 62),
            Position = UDim2.new(0, 10, 1, -72),
            Parent = Sidebar,
        })
        Corner(Profile, 12); Stroke(Profile, Theme.Stroke, 1, 0.2)
        local pfp = New("Frame", {
            BackgroundColor3 = Theme.AccentDeep,
            Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 10, 0.5, -20),
            Parent = Profile,
        })
        Corner(pfp, 20); Gradient(pfp, Theme.Accent, Theme.AccentDeep, 45)
        New("TextLabel", {
            BackgroundTransparency = 1, Text = "🌙",
            TextSize = 20, Size = UDim2.new(1, 0, 1, 0), Parent = pfp,
        })
        New("Frame", {  -- online dot
            BackgroundColor3 = Theme.Success,
            Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -10, 1, -10),
            Parent = pfp,
        }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        New("TextLabel", {
            BackgroundTransparency = 1, Text = userName,
            Font = FONT_BOLD, TextSize = 14, TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 58, 0, 12), Size = UDim2.new(1, -66, 0, 18),
            Parent = Profile,
        })
        local rankTag = New("Frame", {
            BackgroundColor3 = Theme.AccentDeep,
            Position = UDim2.new(0, 58, 0, 32), Size = UDim2.new(0, 90, 0, 18),
            Parent = Profile,
        })
        Corner(rankTag, 6); Gradient(rankTag, Theme.Accent, Theme.AccentDeep, 0)
        New("TextLabel", {
            BackgroundTransparency = 1, Text = "👑 " .. userRank,
            Font = FONT_BOLD, TextSize = 11, TextColor3 = Theme.Text,
            Size = UDim2.new(1, 0, 1, 0), Parent = rankTag,
        })

        --──────────────────────────────────────────────────────────────
        -- HEADER (top bar: discord + window controls) + BODY container
        --──────────────────────────────────────────────────────────────
        local Content = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -190, 1, 0),
            Position = UDim2.new(0, 190, 0, 0),
            Parent = Window,
        })

        local Header = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -24, 0, 54),
            Position = UDim2.new(0, 12, 0, 12),
            Parent = Content,
        })
        makeDraggable(Header, Window)

        -- Discord banner
        local discordBox = New("Frame", {
            BackgroundColor3 = Theme.Card,
            Size = UDim2.new(1, -160, 1, 0),
            Parent = Header,
        })
        Corner(discordBox, 12); Stroke(discordBox, Theme.Stroke, 1, 0.2)
        New("TextLabel", {
            BackgroundTransparency = 1, Text = "💬",
            TextSize = 22, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0, 30, 1, 0),
            Parent = discordBox,
        })
        New("TextLabel", {
            BackgroundTransparency = 1, Text = "Join our Discord community!",
            Font = FONT_BOLD, TextSize = 13, TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 50, 0, 10), Size = UDim2.new(1, -100, 0, 18),
            Parent = discordBox,
        })
        New("TextLabel", {
            BackgroundTransparency = 1, Text = discord,
            Font = FONT, TextSize = 12, TextColor3 = Theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 50, 0, 26), Size = UDim2.new(1, -100, 0, 16),
            Parent = discordBox,
        })
        local dcBtn = New("Frame", {
            BackgroundColor3 = Theme.AccentDeep,
            Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(1, -44, 0.5, -17),
            Parent = discordBox,
        })
        Corner(dcBtn, 8); Gradient(dcBtn, Theme.Accent, Theme.AccentDeep, 45)
        New("TextLabel", {
            BackgroundTransparency = 1, Text = "›",
            Font = FONT_BOLD, TextSize = 20, TextColor3 = Theme.Text,
            Size = UDim2.new(1, 0, 1, 0), Parent = dcBtn,
        })
        New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1,0,1,0), Parent = dcBtn })
            .MouseButton1Click:Connect(function()
                if setclipboard then pcall(setclipboard, discord) end
                notify("Lunar Hub", "Discord link copied!", 2)
            end)

        -- window control buttons
        local function ctrlBtn(icon, xoff, cb, danger)
            local b = New("Frame", {
                BackgroundColor3 = Theme.Card,
                Size = UDim2.new(0, 34, 0, 34),
                Position = UDim2.new(1, xoff, 0.5, -17),
                Parent = Header,
            })
            Corner(b, 8); Stroke(b, Theme.Stroke, 1, 0.3)
            local l = New("TextLabel", {
                BackgroundTransparency = 1, Text = icon,
                Font = FONT_BOLD, TextSize = 15,
                TextColor3 = danger and Theme.Danger or Theme.SubText,
                Size = UDim2.new(1, 0, 1, 0), Parent = b,
            })
            local btn = New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1,0,1,0), Parent = b })
            btn.MouseEnter:Connect(function() Tween(b, 0.15, { BackgroundColor3 = danger and Theme.Danger or Theme.CardHover }) end)
            btn.MouseLeave:Connect(function() Tween(b, 0.15, { BackgroundColor3 = Theme.Card }) end)
            btn.MouseButton1Click:Connect(cb)
            return b
        end

        local minimized = false
        ctrlBtn("⚙", -44, function() notify("Lunar Hub", "Settings", 2) end)
        ctrlBtn("—", -82, function()
            minimized = not minimized
            Tween(Window, 0.3, { Size = minimized and UDim2.new(0, 760, 0, 78) or UDim2.new(0, 760, 0, 500) },
                Enum.EasingStyle.Quart)
        end)
        ctrlBtn("✕", -120, function()
            Tween(Window, 0.3, { Size = UDim2.new(0, 0, 0, 0) },
                Enum.EasingStyle.Back, Enum.EasingDirection.In).Completed:Connect(function()
                ScreenGui:Destroy()
            end)
        end, true)

        -- Body (pages live here)
        local Body = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -24, 1, -78),
            Position = UDim2.new(0, 12, 0, 72),
            Parent = Content,
        })

        --──────────────────────────────────────────────────────────────
        -- TAB ENGINE
        --──────────────────────────────────────────────────────────────
        local WindowObj = {}
        local tabs, tabButtons = {}, {}
        local current = 0

        local function selectTab(index)
            for i, page in ipairs(tabs) do
                page.Visible = (i == index)
            end
            for i, data in ipairs(tabButtons) do
                local active = (i == index)
                Tween(data.frame, 0.2, { BackgroundColor3 = active and Theme.AccentDeep or Theme.Sidebar })
                data.gradient.Enabled = active
                data.stroke.Transparency = active and 0.1 or 1
                Tween(data.label, 0.2, { TextColor3 = active and Theme.Text or Theme.SubText })
                Tween(data.icon,  0.2, { TextColor3 = active and Theme.Text or Theme.Muted })
            end
            current = index
        end

        function WindowObj:AddTab(name, icon)
            local index = #tabs + 1

            -- sidebar button
            local frame = New("Frame", {
                BackgroundColor3 = Theme.Sidebar,
                Size = UDim2.new(1, 0, 0, 42),
                Parent = TabList,
            })
            Corner(frame, 10)
            local grad = Gradient(frame, Theme.Accent, Theme.AccentDeep, 20)
            grad.Enabled = false
            local strk = Stroke(frame, Theme.AccentLight, 1.2, 1)
            local iconLbl = New("TextLabel", {
                BackgroundTransparency = 1, Text = icon or "•",
                Font = FONT_BOLD, TextSize = 16, TextColor3 = Theme.Muted,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0, 24, 1, 0),
                Parent = frame,
            })
            local nameLbl = New("TextLabel", {
                BackgroundTransparency = 1, Text = name,
                Font = FONT_BOLD, TextSize = 14, TextColor3 = Theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 42, 0, 0), Size = UDim2.new(1, -50, 1, 0),
                Parent = frame,
            })
            local btn = New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1,0,1,0), Parent = frame })
            btn.MouseButton1Click:Connect(function() selectTab(index) end)
            btn.MouseEnter:Connect(function()
                if current ~= index then Tween(frame, 0.15, { BackgroundColor3 = Theme.Card }) end
            end)
            btn.MouseLeave:Connect(function()
                if current ~= index then Tween(frame, 0.15, { BackgroundColor3 = Theme.Sidebar }) end
            end)

            tabButtons[index] = { frame = frame, gradient = grad, stroke = strk, label = nameLbl, icon = iconLbl }

            -- page (scrolling)
            local page = New("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Theme.Accent,
                Size = UDim2.new(1, 0, 1, 0),
                CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Visible = false,
                Parent = Body,
            }, {
                New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
                New("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
            })
            tabs[index] = page

            if index == 1 then selectTab(1) end

            local tabApi = buildComponents(page)
            tabApi.Page = page
            tabApi.Button_Frame = frame
            return tabApi
        end

        -- Toast API on the window
        function WindowObj:Notify(cfg)
            cfg = cfg or {}
            local holder = ensureNotifyHolder(ScreenGui)
            local toast = New("Frame", {
                BackgroundColor3 = Theme.Card,
                Size = UDim2.new(1, 0, 0, 60),
                Position = UDim2.new(1, 20, 0, 0),
                Parent = holder,
            })
            Corner(toast, 10); Stroke(toast, Theme.StrokeGlow, 1.2, 0.2)
            New("Frame", {
                BackgroundColor3 = cfg.Color or Theme.Accent,
                Size = UDim2.new(0, 4, 1, -16), Position = UDim2.new(0, 8, 0, 8),
                Parent = toast,
            }, { New("UICorner", { CornerRadius = UDim.new(0, 2) }) })
            New("TextLabel", {
                BackgroundTransparency = 1, Text = cfg.Title or "Notification",
                Font = FONT_BOLD, TextSize = 14, TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 20, 0, 10), Size = UDim2.new(1, -30, 0, 18),
                Parent = toast,
            })
            New("TextLabel", {
                BackgroundTransparency = 1, Text = cfg.Text or "",
                Font = FONT, TextSize = 12, TextColor3 = Theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
                Position = UDim2.new(0, 20, 0, 28), Size = UDim2.new(1, -30, 0, 26),
                Parent = toast,
            })
            Tween(toast, 0.3, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)
            task.delay(cfg.Duration or 4, function()
                Tween(toast, 0.3, { Position = UDim2.new(1, 20, 0, 0) }).Completed:Connect(function()
                    toast:Destroy()
                end)
            end)
        end

        WindowObj.ScreenGui = ScreenGui
        WindowObj.Theme = Theme

        --──────────────────────────────────────────────────────────────
        -- BUILD THE PREMIUM "MAIN" DASHBOARD
        --──────────────────────────────────────────────────────────────
        local Main = WindowObj:AddTab("Main", "🏠")
        do
            local page = Main.Page

            -- Welcome banner
            local banner = New("Frame", {
                BackgroundColor3 = Theme.Card,
                Size = UDim2.new(1, 0, 0, 130),
                Parent = page,
            })
            Corner(banner, 14); Stroke(banner, Theme.Stroke, 1, 0.15)
            Gradient(banner, Color3.fromRGB(46, 18, 52), Color3.fromRGB(20, 11, 30), 20)
            New("TextLabel", {
                BackgroundTransparency = 1, Text = "🌸",
                TextSize = 60, TextTransparency = 0.4,
                Position = UDim2.new(1, -120, 0, 10), Size = UDim2.new(0, 110, 0, 110),
                Parent = banner,
            })
            New("TextLabel", {
                BackgroundTransparency = 1, Text = "Welcome back,",
                Font = FONT, TextSize = 16, TextColor3 = Theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 20, 0, 16), Size = UDim2.new(1, -40, 0, 20),
                Parent = banner,
            })
            local userBig = New("TextLabel", {
                BackgroundTransparency = 1, Text = userName .. " 🌸",
                Font = FONT_BOLD, TextSize = 30, TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 20, 0, 38), Size = UDim2.new(1, -40, 0, 34),
                Parent = banner,
            })
            Gradient(userBig, Theme.AccentLight, Theme.Accent, 90)
            New("TextLabel", {
                BackgroundTransparency = 1, Text = "Welcome to " .. titleText,
                Font = FONT_BOLD, TextSize = 15, TextColor3 = Theme.Accent,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 20, 0, 78), Size = UDim2.new(1, -140, 0, 18),
                Parent = banner,
            })
            New("TextLabel", {
                BackgroundTransparency = 1, Text = welcomeMsg,
                Font = FONT, TextSize = 13, TextColor3 = Theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
                Position = UDim2.new(0, 20, 0, 98), Size = UDim2.new(1, -160, 0, 24),
                Parent = banner,
            })

            -- Feature cards row (Community / Docs / Updates / Premium)
            local cardsRow = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 150),
                Parent = page,
            }, {
                New("UIGridLayout", {
                    CellSize = UDim2.new(0.25, -9, 1, 0),
                    CellPadding = UDim2.new(0, 12, 0, 0),
                    FillDirectionMaxCells = 4,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            })
            local function featureCard(emoji, title, desc, action, cb)
                local c = New("Frame", { BackgroundColor3 = Theme.Card, Parent = cardsRow })
                Corner(c, 12); local cs = Stroke(c, Theme.Stroke, 1, 0.2)
                New("TextLabel", {
                    BackgroundTransparency = 1, Text = emoji, TextSize = 34,
                    Position = UDim2.new(0, 0, 0, 12), Size = UDim2.new(1, 0, 0, 44),
                    Parent = c,
                })
                New("TextLabel", {
                    BackgroundTransparency = 1, Text = title,
                    Font = FONT_BOLD, TextSize = 15, TextColor3 = Theme.Text,
                    Position = UDim2.new(0, 0, 0, 58), Size = UDim2.new(1, 0, 0, 18),
                    Parent = c,
                })
                New("TextLabel", {
                    BackgroundTransparency = 1, Text = desc,
                    Font = FONT, TextSize = 11, TextColor3 = Theme.SubText,
                    TextWrapped = true,
                    Position = UDim2.new(0, 6, 0, 76), Size = UDim2.new(1, -12, 0, 32),
                    Parent = c,
                })
                local pill = New("Frame", {
                    BackgroundColor3 = Theme.Background,
                    Position = UDim2.new(0.5, 0, 1, -34), AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, -20, 0, 26),
                    Parent = c,
                })
                Corner(pill, 8); Stroke(pill, Theme.Accent, 1, 0.4)
                New("TextLabel", {
                    BackgroundTransparency = 1, Text = action .. "  ›",
                    Font = FONT_BOLD, TextSize = 12, TextColor3 = Theme.Accent,
                    Size = UDim2.new(1, 0, 1, 0), Parent = pill,
                })
                local b = New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1,0,1,0), Parent = c })
                b.MouseEnter:Connect(function()
                    Tween(c, 0.15, { BackgroundColor3 = Theme.CardHover }); cs.Color = Theme.Accent; cs.Transparency = 0
                end)
                b.MouseLeave:Connect(function()
                    Tween(c, 0.15, { BackgroundColor3 = Theme.Card }); cs.Color = Theme.Stroke; cs.Transparency = 0.2
                end)
                b.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
            end
            featureCard("🫧", "Community", "Join our amazing community", "Join Now",
                function() if setclipboard then pcall(setclipboard, discord) end WindowObj:Notify({Title="Community", Text="Discord copied to clipboard!"}) end)
            featureCard("📖", "Documentation", "Learn how to use " .. titleText, "Read Docs",
                function() WindowObj:Notify({Title="Documentation", Text="Opening the docs…"}) end)
            featureCard("💎", "Latest Updates", "Check out what's new in v1.0.0", "View Updates",
                function() WindowObj:Notify({Title="Updates", Text="You're on the latest version!"}) end)
            featureCard("👑", "Premium", "Unlock exclusive features", "Upgrade",
                function() WindowObj:Notify({Title="Premium", Text="You already have Premium 💖", Color=Theme.Success}) end)

            -- bottom row : Overview  +  Quick Actions
            local bottomRow = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 150),
                Parent = page,
            })

            -- Overview panel
            local overview = New("Frame", {
                BackgroundColor3 = Theme.Card,
                Size = UDim2.new(0.5, -6, 1, 0),
                Parent = bottomRow,
            })
            Corner(overview, 12); Stroke(overview, Theme.Stroke, 1, 0.2)
            New("TextLabel", {
                BackgroundTransparency = 1, Text = "📈  Overview",
                Font = FONT_BOLD, TextSize = 15, TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 16, 0, 12), Size = UDim2.new(1, -32, 0, 20),
                Parent = overview,
            })
            local statsGrid = New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 42), Size = UDim2.new(1, -24, 1, -54),
                Parent = overview,
            }, {
                New("UIGridLayout", {
                    CellSize = UDim2.new(0.25, -6, 1, 0),
                    CellPadding = UDim2.new(0, 8, 0, 0),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            })
            local function stat(icon, big, small)
                local s = New("Frame", { BackgroundTransparency = 1, Parent = statsGrid })
                New("TextLabel", { BackgroundTransparency = 1, Text = icon, TextSize = 22,
                    Position = UDim2.new(0, 0, 0, 4), Size = UDim2.new(1, 0, 0, 26), Parent = s })
                New("TextLabel", { BackgroundTransparency = 1, Text = big, Font = FONT_BOLD,
                    TextSize = 17, TextColor3 = Theme.Text,
                    Position = UDim2.new(0, 0, 0, 34), Size = UDim2.new(1, 0, 0, 22), Parent = s })
                New("TextLabel", { BackgroundTransparency = 1, Text = small, Font = FONT,
                    TextSize = 11, TextColor3 = Theme.Muted,
                    Position = UDim2.new(0, 0, 0, 56), Size = UDim2.new(1, 0, 0, 16), Parent = s })
            end
            stat("📦", "12,458", "Developers")
            stat("🚀", "98.7%", "Uptime")
            stat("⚡", "v1.0.0", "Version")
            stat("🌐", "24/7", "Support")

            -- Quick Actions panel
            local quick = New("Frame", {
                BackgroundColor3 = Theme.Card,
                Size = UDim2.new(0.5, -6, 1, 0), Position = UDim2.new(0.5, 6, 0, 0),
                Parent = bottomRow,
            })
            Corner(quick, 12); Stroke(quick, Theme.Stroke, 1, 0.2)
            New("TextLabel", {
                BackgroundTransparency = 1, Text = "✨  Quick Actions",
                Font = FONT_BOLD, TextSize = 15, TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 16, 0, 12), Size = UDim2.new(1, -32, 0, 20),
                Parent = quick,
            })
            local qGrid = New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 42), Size = UDim2.new(1, -24, 1, -54),
                Parent = quick,
            }, {
                New("UIGridLayout", {
                    CellSize = UDim2.new(0.5, -5, 0.5, -5),
                    CellPadding = UDim2.new(0, 10, 0, 10),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            })
            local function qAction(icon, text, cb)
                local a = New("Frame", { BackgroundColor3 = Theme.Background, Parent = qGrid })
                Corner(a, 8); local st = Stroke(a, Theme.Stroke, 1, 0.3)
                New("TextLabel", { BackgroundTransparency = 1, Text = icon, TextSize = 16,
                    Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0, 24, 1, 0), Parent = a })
                New("TextLabel", { BackgroundTransparency = 1, Text = text, Font = FONT_MED,
                    TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 38, 0, 0), Size = UDim2.new(1, -60, 1, 0), Parent = a })
                New("TextLabel", { BackgroundTransparency = 1, Text = "›", Font = FONT_BOLD,
                    TextSize = 16, TextColor3 = Theme.Accent,
                    Position = UDim2.new(1, -20, 0, 0), Size = UDim2.new(0, 16, 1, 0), Parent = a })
                local b = New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1,0,1,0), Parent = a })
                b.MouseEnter:Connect(function() Tween(a, 0.15, { BackgroundColor3 = Theme.CardHover }); st.Color = Theme.Accent end)
                b.MouseLeave:Connect(function() Tween(a, 0.15, { BackgroundColor3 = Theme.Background }); st.Color = Theme.Stroke end)
                b.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
            end
            qAction("➕", "Create New Tab", function() WindowObj:Notify({Title="Quick Action", Text="Use Window:AddTab() in code 🌙"}) end)
            qAction("📥", "Import Config", function() WindowObj:Notify({Title="Config", Text="Config imported!"}) end)
            qAction("📤", "Export Config", function() WindowObj:Notify({Title="Config", Text="Config exported!"}) end)
            qAction("🎨", "UI Settings",   function() WindowObj:Notify({Title="UI Settings", Text="Theme is looking premium 💖"}) end)
        end

        -- opening toast
        task.delay(0.5, function()
            WindowObj:Notify({ Title = "🌙 " .. titleText, Text = "Loaded successfully. Welcome, " .. userName .. "!" })
        end)

        return WindowObj
    end
end

--══════════════════════════════════════════════════════════════════════
--  EXAMPLE USAGE  —  edit / add your own tabs below
--══════════════════════════════════════════════════════════════════════
local Window = Lunar:CreateWindow({
    Title    = "LUNAR HUB",
    Subtitle = "月 の 力",
    Discord  = "discord.gg/lunarhub",
    User     = game.Players.LocalPlayer.DisplayName,
    Rank     = "Premium",
    Welcome  = "A premium Roblox UI Library made for developers.",
})

-- ── PLAYER TAB ────────────────────────────────────────────────
local Player = Window:AddTab("Player", "👤")
Player:Section("Movement")
Player:Slider({
    Text = "WalkSpeed", Min = 16, Max = 250, Default = 16,
    Callback = function(v)
        local c = game.Players.LocalPlayer.Character
        if c and c:FindFirstChildOfClass("Humanoid") then
            c:FindFirstChildOfClass("Humanoid").WalkSpeed = v
        end
    end,
})
Player:Slider({
    Text = "JumpPower", Min = 50, Max = 500, Default = 50,
    Callback = function(v)
        local c = game.Players.LocalPlayer.Character
        if c and c:FindFirstChildOfClass("Humanoid") then
            c:FindFirstChildOfClass("Humanoid").JumpPower = v
            c:FindFirstChildOfClass("Humanoid").UseJumpPower = true
        end
    end,
})
local infJump = false
Player:Toggle({
    Text = "Infinite Jump", Default = false,
    Callback = function(on) infJump = on end,
})
game:GetService("UserInputService").JumpRequest:Connect(function()
    if infJump then
        local c = game.Players.LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

Player:Section("Character")
Player:Button({
    Text = "Reset Character",
    Callback = function()
        local c = game.Players.LocalPlayer.Character
        if c and c:FindFirstChildOfClass("Humanoid") then
            c:FindFirstChildOfClass("Humanoid").Health = 0
        end
    end,
})

-- ── VISUALS TAB ───────────────────────────────────────────────
local Visuals = Window:AddTab("Visuals", "🎨")
Visuals:Section("ESP")
Visuals:Toggle({ Text = "Player ESP",    Default = false, Callback = function(on) end })
Visuals:Toggle({ Text = "Name Tags",     Default = false, Callback = function(on) end })
Visuals:Dropdown({
    Text = "ESP Color", Options = { "Pink", "White", "Red", "Green" }, Default = "Pink",
    Callback = function(opt) end,
})
Visuals:Section("Camera")
Visuals:Slider({ Text = "Field of View", Min = 70, Max = 120, Default = 70,
    Callback = function(v) pcall(function() workspace.CurrentCamera.FieldOfView = v end) end })

-- ── WORLD TAB ─────────────────────────────────────────────────
local World = Window:AddTab("World", "🌐")
World:Section("Environment")
World:Toggle({ Text = "Full Bright", Default = false, Callback = function(on)
    local l = game:GetService("Lighting")
    l.Brightness = on and 3 or 1
    l.ClockTime  = on and 14 or 14
end })
World:Slider({ Text = "Time of Day", Min = 0, Max = 24, Default = 14,
    Callback = function(v) game:GetService("Lighting").ClockTime = v end })

-- ── MISC TAB ──────────────────────────────────────────────────
local Misc = Window:AddTab("Misc", "🧩")
Misc:Section("Utilities")
Misc:Textbox({ Text = "Chat Message", Placeholder = "Say something…",
    Callback = function(txt) end })
Misc:Keybind({ Text = "Toggle UI", Default = Enum.KeyCode.RightShift,
    Callback = function() Window:Notify({ Title = "Keybind", Text = "UI toggle pressed!" }) end })
Misc:Paragraph("About", "Lunar Hub — a premium custom UI made just for your hub. Add unlimited tabs, and every control automatically matches the pink Lunar theme.")

-- ── SETTINGS TAB ──────────────────────────────────────────────
local Settings = Window:AddTab("Settings", "⚙️")
Settings:Section("Configuration")
Settings:Button({ Text = "Copy Discord Invite", Callback = function()
    if setclipboard then pcall(setclipboard, "discord.gg/lunarhub") end
    Window:Notify({ Title = "Copied", Text = "Discord invite copied!" })
end })
Settings:Button({ Text = "Unload Lunar Hub", Callback = function()
    Window.ScreenGui:Destroy()
end })

return Lunar
