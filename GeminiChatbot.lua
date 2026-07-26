--[[
    Proximity AI Chatbot (client / executor LocalScript)
    ----------------------------------------------------
    Listens to nearby players' chat messages and replies in the RBXGeneral
    channel using the Pollinations AI text API (keyless / free).

    Notes:
      * No API key required - Pollinations is used anonymously.
      * Any promotional/ad text Pollinations may append to a response is
        stripped before the reply is sent to chat.
      * HTTP goes through the executor `request` global (request /
        http_request / syn.request / fluxus) and only falls back to
        HttpService:RequestAsync (which is blocked in vanilla LocalScripts).
      * Replies are sanitised: trimmed, newlines stripped, truncated to
        Roblox's 200-character chat limit.
      * An on-screen notification confirms the script loaded, and errors are
        surfaced as notifications instead of console-only warnings.
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- Pollinations AI Configuration (no API key needed)
local MODEL = "gpt-5.6-sol"                          -- model name
local API_URL = "https://text.pollinations.ai/openai" -- OpenAI-compatible endpoint

local TALK_DISTANCE = 15    -- Distance in studs to trigger response
local COOLDOWN_TIME = 3     -- Seconds between responses to prevent spam
local MAX_CHAT_LENGTH = 200 -- Roblox chat hard limit
local lastResponseTime = 0

local generalChannel -- cached RBXGeneral TextChannel

-- On-screen notification helper (so failures aren't hidden in the console).
local function notify(title, text, duration)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 5,
		})
	end)
end

-- Resolve an executor HTTP request function (falls back to HttpService).
-- Vanilla HttpService HTTP calls are blocked in LocalScripts, so an
-- executor-provided request function is required for this to work at all.
local function httpRequest(options)
	local requestFn = (syn and syn.request)
		or (fluxus and fluxus.request)
		or http_request
		or (http and http.request)
		or request

	if requestFn then
		local response = requestFn(options)
		-- Normalise: executor responses expose StatusCode + Body.
		return {
			StatusCode = response.StatusCode or (response.Success and 200 or 0),
			StatusMessage = response.StatusMessage or "",
			Body = response.Body,
		}
	end

	-- Fallback for environments where HttpService requests are permitted.
	local response = HttpService:RequestAsync(options)
	return {
		StatusCode = response.StatusCode,
		StatusMessage = response.StatusMessage,
		Body = response.Body,
	}
end

-- Remove any Pollinations ad / promotional text from a raw model reply.
-- Ads are typically appended as a trailing paragraph and/or contain a
-- markdown link or a mention of the service, so drop offending lines.
local function stripAds(text)
	if type(text) ~= "string" then
		return nil
	end

	local kept = {}
	-- Iterate line-by-line (append a newline so the last line is captured).
	for line in (text .. "\n"):gmatch("(.-)\n") do
		local lower = line:lower()
		local isAd = lower:find("pollinations", 1, true)
			or lower:find("sponsor", 1, true)
			or lower:find("advertis", 1, true)
			or lower:find("powered by", 1, true)
			or lower:find("support us", 1, true)
			or lower:find("%[.-%]%(https?://") -- markdown link line
		if not isAd then
			table.insert(kept, line)
		end
	end

	text = table.concat(kept, " ")
	-- Strip any remaining inline markdown links and bare URLs.
	text = text:gsub("%[[^%]]*%]%([^%)]*%)", "")
	text = text:gsub("https?://%S+", "")
	return text
end

-- Query Pollinations for a reply, with HTTP status & error handling.
local function getAIResponse(userMessage, senderDisplayName)
	local payload = {
		model = MODEL,
		messages = {
			{
				role = "system",
				content = "You are playing a Roblox game. A player named " .. senderDisplayName .. " standing next to you said something. " ..
				          "Respond in a natural, casual, and brief gamer style (1 short sentence max). " ..
				          "Do not include any links, ads, or promotional text.",
			},
			{
				role = "user",
				content = userMessage,
			},
		},
		private = true, -- keep the exchange out of the public feed
		referrer = "roblox",
	}

	local jsonPayload = HttpService:JSONEncode(payload)

	local success, response = pcall(httpRequest, {
		Url = API_URL,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json"
		},
		Body = jsonPayload
	})

	-- 1. Handle Network / Transport Errors (e.g., no internet, blocked requests)
	if not success then
		warn("[Pollinations Network Error]: Failed to issue HTTP request. Details:", tostring(response))
		notify("AI Chatbot", "Network error - request could not be sent.")
		return nil
	end

	-- Guard against an empty/nil body before attempting to decode.
	local decodeSuccess, decoded = false, nil
	if type(response.Body) == "string" and response.Body ~= "" then
		decodeSuccess, decoded = pcall(function()
			return HttpService:JSONDecode(response.Body)
		end)
	end

	-- 2. Check HTTP Status Code
	if response.StatusCode ~= 200 then
		warn(string.format("[Pollinations HTTP Error %d]: %s", response.StatusCode, tostring(response.StatusMessage)))

		local apiMessage
		if decodeSuccess and decoded and decoded.error then
			apiMessage = (type(decoded.error) == "table" and decoded.error.message) or tostring(decoded.error)
			warn("  -> API Message:", apiMessage)
		else
			warn("  -> Raw Response Body:", tostring(response.Body))
		end
		notify("AI Chatbot", string.format("API error %d: %s", response.StatusCode, apiMessage or "see console"), 8)
		return nil
	end

	-- 3. Process Successful (200 OK) Payload (OpenAI-compatible shape).
	if decodeSuccess and decoded then
		if decoded.choices and #decoded.choices > 0 then
			local choice = decoded.choices[1]
			if choice.message and type(choice.message.content) == "string" then
				return choice.message.content
			end
		end
		warn("[Pollinations Warning]: HTTP 200 returned, but payload missing expected message content.")
	else
		-- Some Pollinations endpoints return plain text rather than JSON.
		if type(response.Body) == "string" and response.Body ~= "" then
			return response.Body
		end
		warn("[Pollinations Error]: Failed to parse response body.")
	end

	return nil
end

-- Clean up a raw model reply so it is safe for the chat box.
local function sanitizeReply(text)
	if type(text) ~= "string" then
		return nil
	end
	-- Collapse newlines to spaces and trim surrounding whitespace.
	text = text:gsub("[\r\n]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	-- Collapse runs of spaces left behind by ad stripping.
	text = text:gsub("%s%s+", " ")
	if text == "" then
		return nil
	end
	if #text > MAX_CHAT_LENGTH then
		text = text:sub(1, MAX_CHAT_LENGTH)
	end
	return text
end

-- Function to send chat message back to the channel
local function sendChatMessage(message)
	if generalChannel then
		generalChannel:SendAsync(message)
	else
		warn("[TextChatService Error]: RBXGeneral channel could not be found.")
	end
end

-- Setup Modern TextChatService Event Listener
local function setupTextChatListener()
	if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
		warn("[TextChatService Error]: Game is using the legacy chat system; this script requires TextChatService.")
		notify("AI Chatbot", "This game uses legacy chat - chatbot cannot run here.", 8)
		return
	end

	local textChannels = TextChatService:WaitForChild("TextChannels", 10)
	if not textChannels then
		warn("[TextChatService Error]: TextChannels folder not found.")
		return
	end

	generalChannel = textChannels:WaitForChild("RBXGeneral", 10)
	if not generalChannel then
		warn("[TextChatService Error]: RBXGeneral channel not found.")
		return
	end

	-- Replacing player.Chatted with TextChannel.MessageReceived
	generalChannel.MessageReceived:Connect(function(textChatMessage)
		local textSource = textChatMessage.TextSource
		if not textSource then return end

		-- Get player object from UserId and ignore self
		local senderPlayer = Players:GetPlayerByUserId(textSource.UserId)
		if not senderPlayer or senderPlayer == LocalPlayer then return end

		-- Ignore empty / whitespace-only messages
		local incoming = textChatMessage.Text
		if type(incoming) ~= "string" or incoming:gsub("%s", "") == "" then return end

		-- Distance calculation between LocalPlayer and Sender
		local myCharacter = LocalPlayer.Character
		local targetCharacter = senderPlayer.Character
		if not (myCharacter and targetCharacter) then return end

		local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
		local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
		if not (myRoot and targetRoot) then return end

		local distance = (myRoot.Position - targetRoot.Position).Magnitude
		if distance <= TALK_DISTANCE then
			local currentTime = tick()
			if currentTime - lastResponseTime < COOLDOWN_TIME then
				return
			end
			lastResponseTime = currentTime

			task.spawn(function()
				local reply = sanitizeReply(stripAds(getAIResponse(incoming, senderPlayer.DisplayName)))
				if reply then
					sendChatMessage(reply)
				end
			end)
		end
	end)

	-- Listener is live: tell the user the script loaded successfully.
	notify("AI Chatbot", string.format("Loaded! Replying to players within %d studs.", TALK_DISTANCE), 6)
	print("[AI Chatbot]: Loaded and listening on RBXGeneral (Pollinations / " .. MODEL .. ").")
end

setupTextChatListener()
