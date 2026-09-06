--[[
	NovaMCP • Studio plugin
	----------------------------------------------------------------------
	The Studio side of the Nova Roblox MCP bridge. It long-polls the local
	MCP server for commands, runs them against the open place's DataModel,
	and posts the results back — letting an attached AI agent see the tree,
	edit instances, write/run Luau, and build animations.

	INSTALL
	  1. In Studio: enable HTTP — Game Settings ▸ Security ▸ "Allow HTTP
	     Requests" (or Home ▸ Game Settings). Localhost is still localhost.
	  2. Save this file into your Studio plugins folder as a Local Plugin,
	     or right-click it in Explorer ▸ "Save as Local Plugin".
	  3. Start the MCP server (see roblox-mcp/README.md) and click the
	     "NovaMCP: Connect" toolbar button.

	SECURITY: this runs whatever Luau the agent sends, inside your edit
	session. Only connect to a server you started yourself, on localhost.
]]

local HttpService     = game:GetService("HttpService")
local Selection       = game:GetService("Selection")
local ChangeHistory   = game:GetService("ChangeHistoryService")

local BASE  = "http://127.0.0.1:3005"
local TOKEN = "nova-dev-token"   -- must match NOVA_MCP_TOKEN on the server

-- ── toolbar toggle ────────────────────────────────────────────────────────
local toolbar = plugin:CreateToolbar("NovaMCP")
local button  = toolbar:CreateButton("Connect", "Attach the AI agent to this place", "")
button.ClickableWhenViewportHidden = true

local running = false

-- ── path helpers ──────────────────────────────────────────────────────────
local function resolvePath(path)
	if not path or path == "" or path == "game" then return game end
	local node = game
	for seg in string.gmatch(path, "[^%.]+") do
		if seg == "game" then
			node = game
		else
			local nextNode
			if node == game then
				local ok, svc = pcall(function() return game:GetService(seg) end)
				nextNode = (ok and svc) or node:FindFirstChild(seg)
			else
				nextNode = node:FindFirstChild(seg)
			end
			if not nextNode then
				error("No instance at path segment '" .. seg .. "' in '" .. path .. "'")
			end
			node = nextNode
		end
	end
	return node
end

local function pathOf(inst)
	if inst == game then return "game" end
	local ok, full = pcall(function() return inst:GetFullName() end)
	return ok and full or inst.Name
end

-- ── value <-> JSON codecs ──────────────────────────────────────────────────
local function round(n) return math.floor(n * 1000 + 0.5) / 1000 end

local function encodeValue(v, depth)
	depth = depth or 0
	local t = typeof(v)
	if t == "string" or t == "number" or t == "boolean" or t == "nil" then
		return v
	elseif t == "Instance" then
		return { __t = "Instance", path = pathOf(v), class = v.ClassName, name = v.Name }
	elseif t == "Vector3" then
		return { __t = "Vector3", x = round(v.X), y = round(v.Y), z = round(v.Z) }
	elseif t == "Vector2" then
		return { __t = "Vector2", x = round(v.X), y = round(v.Y) }
	elseif t == "Color3" then
		return { __t = "Color3", r = math.round(v.R * 255), g = math.round(v.G * 255), b = math.round(v.B * 255) }
	elseif t == "UDim2" then
		return { __t = "UDim2", xs = v.X.Scale, xo = v.X.Offset, ys = v.Y.Scale, yo = v.Y.Offset }
	elseif t == "UDim" then
		return { __t = "UDim", scale = v.Scale, offset = v.Offset }
	elseif t == "CFrame" then
		return { __t = "CFrame", comps = { v:GetComponents() } }
	elseif t == "EnumItem" then
		return { __t = "EnumItem", enum = tostring(v.EnumType), name = v.Name, value = v.Value }
	elseif t == "table" then
		if depth > 4 then return tostring(v) end
		local out = {}
		for k, val in pairs(v) do out[tostring(k)] = encodeValue(val, depth + 1) end
		return out
	end
	return tostring(v)
end

local function decodeValue(v)
	if type(v) ~= "table" then return v end
	local tag = v.__t
	if not tag then return v end
	if tag == "Vector3" then return Vector3.new(v.x, v.y, v.z)
	elseif tag == "Vector2" then return Vector2.new(v.x, v.y)
	elseif tag == "Color3" then return Color3.fromRGB(v.r, v.g, v.b)
	elseif tag == "UDim2" then return UDim2.new(v.xs or 0, v.xo or 0, v.ys or 0, v.yo or 0)
	elseif tag == "UDim" then return UDim.new(v.scale or 0, v.offset or 0)
	elseif tag == "CFrame" then
		if v.comps then return CFrame.new(table.unpack(v.comps)) end
		local pos = CFrame.new(v.px or 0, v.py or 0, v.pz or 0)
		if v.rx or v.ry or v.rz then
			pos = pos * CFrame.Angles(math.rad(v.rx or 0), math.rad(v.ry or 0), math.rad(v.rz or 0))
		end
		return pos
	elseif tag == "EnumItem" then
		return Enum[v.enum][v.name]
	elseif tag == "Instance" then
		return resolvePath(v.path)
	end
	return v
end

-- ── command handlers ───────────────────────────────────────────────────────
local Handlers = {}

function Handlers.get_tree(a)
	local root = resolvePath(a.path or "game")
	local maxDepth = a.depth or 3
	local function walk(inst, depth)
		local node = { name = inst.Name, class = inst.ClassName, path = pathOf(inst) }
		if depth < maxDepth then
			local kids = {}
			for _, c in ipairs(inst:GetChildren()) do
				table.insert(kids, walk(c, depth + 1))
			end
			if #kids > 0 then node.children = kids end
		else
			local n = #inst:GetChildren()
			if n > 0 then node.childCount = n end
		end
		return node
	end
	return walk(root, 0)
end

local READABLE = {
	"Name", "ClassName", "Position", "Size", "CFrame", "Orientation", "Anchored",
	"Color", "BrickColor", "Material", "Transparency", "CanCollide", "Text",
	"BackgroundColor3", "Visible", "Value", "Enabled", "TextColor3", "Image",
}
function Handlers.get_properties(a)
	local inst = resolvePath(a.path)
	local props = {}
	for _, name in ipairs(READABLE) do
		local ok, val = pcall(function() return inst[name] end)
		if ok and val ~= nil then props[name] = encodeValue(val) end
	end
	return { path = pathOf(inst), properties = props }
end

local function applyProps(inst, properties)
	local applied, errors = {}, {}
	for name, raw in pairs(properties or {}) do
		local ok, err = pcall(function() inst[name] = decodeValue(raw) end)
		if ok then table.insert(applied, name) else errors[name] = tostring(err) end
	end
	return applied, errors
end

function Handlers.create_instance(a)
	local parent = resolvePath(a.parent or "game.Workspace")
	local inst = Instance.new(a.className)
	if a.name then inst.Name = a.name end
	local applied, errors = applyProps(inst, a.properties)
	inst.Parent = parent
	ChangeHistory:SetWaypoint("NovaMCP create " .. a.className)
	return { path = pathOf(inst), applied = applied, errors = errors }
end

function Handlers.set_property(a)
	local inst = resolvePath(a.path)
	inst[a.property] = decodeValue(a.value)
	ChangeHistory:SetWaypoint("NovaMCP set " .. a.property)
	return { path = pathOf(inst), property = a.property, ok = true }
end

function Handlers.delete_instance(a)
	local inst = resolvePath(a.path)
	local name = pathOf(inst)
	inst:Destroy()
	ChangeHistory:SetWaypoint("NovaMCP delete")
	return { deleted = name }
end

function Handlers.select(a)
	local list = {}
	for _, p in ipairs(a.paths or {}) do table.insert(list, resolvePath(p)) end
	Selection:Set(list)
	return { selected = #list }
end

function Handlers.insert_script(a)
	local parent = resolvePath(a.parent or "game.ServerScriptService")
	local inst = Instance.new(a.scriptType or "Script")
	inst.Name = a.name or "Script"
	inst.Source = a.source or ""
	inst.Parent = parent
	ChangeHistory:SetWaypoint("NovaMCP insert script")
	return { path = pathOf(inst) }
end

function Handlers.get_source(a)
	local inst = resolvePath(a.path)
	return { path = pathOf(inst), source = inst.Source }
end

function Handlers.run_luau(a)
	-- Wrap the snippet as a module body so `return` yields a value.
	local ms = Instance.new("ModuleScript")
	ms.Name = "NovaMCP_Exec"
	ms.Source = "return function()\n" .. (a.source or "") .. "\nend"
	ms.Parent = game:GetService("ServerStorage")
	local okLoad, fn = pcall(require, ms)
	if not okLoad then ms:Destroy(); error("compile error: " .. tostring(fn)) end
	local okRun, result = pcall(fn)
	ms:Destroy()
	if not okRun then error("runtime error: " .. tostring(result)) end
	return { result = encodeValue(result) }
end

function Handlers.create_animation(a)
	local parent = resolvePath(a.parent or "game.Workspace")
	local seq = Instance.new("KeyframeSequence")
	seq.Name = a.name or "NovaAnimation"
	for _, kf in ipairs(a.keyframes or {}) do
		local keyframe = Instance.new("Keyframe")
		keyframe.Time = kf.time or 0
		for bone, cf in pairs(kf.poses or {}) do
			local pose = Instance.new("Pose")
			pose.Name = bone
			pose.CFrame = decodeValue(cf)
			pose.Parent = keyframe
		end
		keyframe.Parent = seq
	end
	seq.Parent = parent
	ChangeHistory:SetWaypoint("NovaMCP animation")
	return {
		path = pathOf(seq),
		note = "Right-click the KeyframeSequence in Explorer ▸ Save to Roblox to get an animation asset id.",
	}
end

-- ── networking ──────────────────────────────────────────────────────────────
local function request(pathPart, method, body)
	return HttpService:RequestAsync({
		Url = BASE .. pathPart,
		Method = method,
		Headers = {
			["x-nova-token"] = TOKEN,
			["Content-Type"] = "application/json",
		},
		Body = body and HttpService:JSONEncode(body) or nil,
	})
end

local function postResult(id, ok, payload)
	pcall(function()
		request("/result", "POST", ok and { id = id, ok = true, result = payload }
			or { id = id, ok = false, error = tostring(payload) })
	end)
end

local function handleCommand(cmd)
	local fn = Handlers[cmd.tool]
	if not fn then
		postResult(cmd.id, false, "unknown tool: " .. tostring(cmd.tool))
		return
	end
	local ok, res = pcall(fn, cmd.args or {})
	postResult(cmd.id, ok, res)
end

local function loop()
	while running do
		local ok, resp = pcall(request, "/poll", "GET")
		if not ok then
			warn("[NovaMCP] bridge unreachable — is the server running? Retrying…")
			task.wait(2)
		elseif resp.StatusCode == 200 then
			local decoded
			local decodeOk = pcall(function() decoded = HttpService:JSONDecode(resp.Body) end)
			if decodeOk and decoded and decoded.id then
				task.spawn(handleCommand, decoded)
			end
		elseif resp.StatusCode == 204 then
			-- no command in this window; poll again immediately
		else
			task.wait(1)
		end
	end
end

button.Click:Connect(function()
	running = not running
	button:SetActive(running)
	if running then
		if not HttpService.HttpEnabled then
			warn("[NovaMCP] HTTP is disabled. Enable Game Settings ▸ Security ▸ Allow HTTP Requests.")
		end
		print("[NovaMCP] connecting to " .. BASE)
		task.spawn(loop)
	else
		print("[NovaMCP] disconnected.")
	end
end)

plugin.Unloading:Connect(function() running = false end)
