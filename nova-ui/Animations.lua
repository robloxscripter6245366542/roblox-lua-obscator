--[[
	NovaUI • Animations
	----------------------------------------------------------------------
	A small motion toolkit for Roblox UI. Reusable, tween-based animation
	presets — the kind of polish the popular UI libraries (Rayfield, Fluent,
	WindUI) use for opens, hovers and list reveals — exposed as one-liners.

		local Anim = require(script.Parent.Animations)

		Anim.PopIn(frame)                     -- scale + fade entrance
		Anim.SlideIn(frame, "Bottom")         -- slide from an edge
		Anim.Stagger(container, "PopIn", 0.04)-- reveal children in sequence
		Anim.Hover(button)                    -- wire hover grow/shrink
		Anim.Pulse(icon)                      -- attention pulse (loops once)
		local stop = Anim.Spin(loader)        -- infinite spin; call stop()

	Everything is pure TweenService — no external assets — so it works in any
	experience and alongside NovaUI / Shop.
]]

local TweenService = game:GetService("TweenService")

local Anim = {}

-- Named easing presets.
local E = {
	Snappy = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
	Smooth = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Spring = TweenInfo.new(0.45, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
	Gentle = TweenInfo.new(0.35, Enum.EasingStyle.Sine,  Enum.EasingDirection.Out),
}
Anim.Easing = E

local function play(inst, info, props)
	local t = TweenService:Create(inst, info, props)
	t:Play()
	return t
end

-- Ensure a frame has a UIScale we can animate without touching its size.
local function scaleOf(inst)
	local s = inst:FindFirstChildOfClass("UIScale")
	if not s then
		s = Instance.new("UIScale")
		s.Scale = 1
		s.Parent = inst
	end
	return s
end

-- ── Entrances ────────────────────────────────────────────────────────────

-- Scale-up + fade entrance. Returns the tween.
function Anim.PopIn(inst, info)
	local s = scaleOf(inst)
	s.Scale = 0.85
	inst.Visible = true
	if inst:IsA("GuiObject") then inst.BackgroundTransparency = inst.BackgroundTransparency end
	return play(s, info or E.Spring, { Scale = 1 })
end

-- Fade the frame (and immediate text/image children) from transparent.
function Anim.FadeIn(inst, info)
	info = info or E.Gentle
	inst.Visible = true
	local function fade(o, target, prop)
		local cur = o[prop]
		o[prop] = 1
		play(o, info, { [prop] = target })
	end
	if inst:IsA("GuiObject") then fade(inst, inst.BackgroundTransparency, "BackgroundTransparency") end
	for _, c in ipairs(inst:GetDescendants()) do
		if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("TextBox") then
			play(c, info, { TextTransparency = 0 })
		elseif c:IsA("ImageLabel") or c:IsA("ImageButton") then
			play(c, info, { ImageTransparency = 0 })
		end
	end
end

-- Slide in from an edge: "Top" | "Bottom" | "Left" | "Right".
function Anim.SlideIn(inst, from, info)
	from = from or "Bottom"
	local target = inst.Position
	local off = 60
	local start = ({
		Top    = target - UDim2.fromOffset(0, off),
		Bottom = target + UDim2.fromOffset(0, off),
		Left   = target - UDim2.fromOffset(off, 0),
		Right  = target + UDim2.fromOffset(off, 0),
	})[from] or (target + UDim2.fromOffset(0, off))
	inst.Position = start
	inst.Visible = true
	return play(inst, info or E.Smooth, { Position = target })
end

-- ── Exits ────────────────────────────────────────────────────────────────

-- Scale-down + hide. Runs `onDone` when finished.
function Anim.PopOut(inst, onDone, info)
	local s = scaleOf(inst)
	local t = play(s, info or E.Snappy, { Scale = 0.85 })
	t.Completed:Connect(function()
		inst.Visible = false
		if onDone then onDone() end
	end)
	return t
end

-- ── Reveal a list ────────────────────────────────────────────────────────

-- Run an entrance (name of an Anim function) across a container's children,
-- offset by `gap` seconds each — the classic staggered menu reveal.
function Anim.Stagger(container, animName, gap, ...)
	local fn = Anim[animName or "PopIn"]
	if not fn then return end
	gap = gap or 0.04
	local i = 0
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			local delay = i * gap
			i += 1
			task.delay(delay, fn, child, ...)
		end
	end
end

-- ── Interaction wiring ───────────────────────────────────────────────────

-- Grow on hover, shrink on press. Works for buttons and frames.
function Anim.Hover(inst, growTo)
	growTo = growTo or 1.04
	local s = scaleOf(inst)
	inst.MouseEnter:Connect(function() play(s, E.Snappy, { Scale = growTo }) end)
	inst.MouseLeave:Connect(function() play(s, E.Snappy, { Scale = 1 }) end)
	if inst:IsA("GuiButton") then
		inst.MouseButton1Down:Connect(function() play(s, E.Snappy, { Scale = 0.96 }) end)
		inst.MouseButton1Up:Connect(function() play(s, E.Snappy, { Scale = growTo }) end)
	end
	return inst
end

-- ── Loops / attention ────────────────────────────────────────────────────

-- One attention pulse (out then back).
function Anim.Pulse(inst)
	local s = scaleOf(inst)
	play(s, E.Snappy, { Scale = 1.12 }).Completed:Connect(function()
		play(s, E.Spring, { Scale = 1 })
	end)
end

-- Infinite rotation. Returns a stop() function.
function Anim.Spin(inst, speed)
	local running = true
	task.spawn(function()
		while running and inst.Parent do
			inst.Rotation = (inst.Rotation + (speed or 6)) % 360
			task.wait()
		end
	end)
	return function() running = false end
end

-- Number roll-up: animate a numeric label from its current value to `to`.
function Anim.CountTo(label, to, duration, prefix)
	prefix = prefix or ""
	duration = duration or 0.6
	local from = tonumber(string.match(label.Text, "%d+")) or 0
	local start = os.clock()
	task.spawn(function()
		while true do
			local a = math.clamp((os.clock() - start) / duration, 0, 1)
			local v = math.floor(from + (to - from) * a)
			label.Text = prefix .. tostring(v)
			if a >= 1 then break end
			task.wait()
		end
	end)
end

return Anim
