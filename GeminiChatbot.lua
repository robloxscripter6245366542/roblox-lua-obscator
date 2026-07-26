--[[
    Gemini Proximity Chatbot (client / executor LocalScript)
    ---------------------------------------------------------
    Listens to nearby players' chat messages and replies in the RBXGeneral
    channel using Google's Gemini API.

    Bug fixes / hardening in this version:
      * HTTP now works inside executors: uses the exploit `request` global
        (request / http_request / syn.request / fluxus) and only falls back
        to HttpService:RequestAsync. Vanilla HttpService HTTP calls do NOT
        work from a LocalScript, which is why the original never responded.
      * Response fields from every request backend are normalised, so status
        code / body handling works regardless of which executor is used.
      * response.Body is validated before JSONDecode (no crash on empty body).
      * Replies are sanitised: trimmed, newlines stripped, and truncated to
        Roblox's 200-character chat limit (SendAsync silently fails on longer).
      * Empty / whitespace-only incoming messages are ignored.
      * The channel reference is cached from setup instead of re-searching.
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer

-- Gemini API Configuration
local API_KEY = "AQ.Ab8RN6LhqzbrfbDy5UWbBu-BvB0glwyEDbvg1FnOAiAGsAuSpw"
local API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" .. API_KEY

local TALK_DISTANCE = 15   -- Distance in studs to trigger response
local COOLDOWN_TIME = 3    -- Seconds between responses to prevent spam
local MAX_CHAT_LENGTH = 200 -- Roblox chat hard limit
local lastResponseTime = 0

local generalChannel -- cached RBXGeneral TextChannel

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

-- Function to send query to Gemini API with HTTP status & error handling
local function getGeminiResponse(userMessage, senderDisplayName)
	local payload = {
		systemInstruction = {
			parts = {
				{
					text = "You are playing a Roblox game. A player named " .. senderDisplayName .. " standing next to you said something. " ..
					       "Respond in a natural, casual, and brief gamer style (1 short sentence max)."
				}
			}
		},
		contents = {
			{
				role = "user",
				parts = { { text = userMessage } }
			}
		}
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
		warn("[Gemini API Network Error]: Failed to issue HTTP request. Details:", tostring(response))
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
		warn(string.format("[Gemini API HTTP Error %d]: %s", response.StatusCode, tostring(response.StatusMessage)))

		-- 3. Parse and log explicit Gemini API error response structure
		if decodeSuccess and decoded and decoded.error then
			local err = decoded.error
			warn(string.format("  -> API Error Code: %s", tostring(err.code or "N/A")))
			warn(string.format("  -> API Status: %s", err.status or "N/A"))
			warn(string.format("  -> API Message: %s", err.message or "No message provided"))
		else
			warn("  -> Raw Response Body:", tostring(response.Body))
		end
		return nil
	end

	-- 4. Process Successful (200 OK) Payload
	if decodeSuccess and decoded then
		if decoded.candidates and #decoded.candidates > 0 then
			local candidate = decoded.candidates[1]
			if candidate.content and candidate.content.parts and #candidate.content.parts > 0 then
				return candidate.content.parts[1].text
			end
		end
		warn("[Gemini API Warning]: HTTP 200 returned, but payload missing expected text parts.")
	else
		warn("[Gemini API Error]: Failed to parse JSON body on successful HTTP response.")
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
				local reply = sanitizeReply(getGeminiResponse(incoming, senderPlayer.DisplayName))
				if reply then
					sendChatMessage(reply)
				end
			end)
		end
	end)
end

setupTextChatListener()
