-- Chat Tag Client
-- Displays chat tags in TextChatService

local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getChatTagFunction = ReplicatedStorage:WaitForChild("GetChatTagData", 10)
if not getChatTagFunction then
	warn("[ChatTag Client] GetChatTagData RemoteFunction not found!")
	return
end

-- Convert Color3 to hex
local function colorToHex(color)
	return string.format(
		"#%02X%02X%02X",
		math.floor(color.R * 255),
		math.floor(color.G * 255),
		math.floor(color.B * 255)
	)
end

-- Cache for chat tags (reduce server calls)
local chatTagCache = {}
local CACHE_DURATION = 5

local function getChatTag(userId)
	local now = tick()
	local cached = chatTagCache[userId]

	-- Return cached if valid
	if cached and (now - cached.lastUpdate) < CACHE_DURATION then
		return cached.tag, cached.tagColor
	end

	-- Request from server
	local success, result = pcall(function()
		return getChatTagFunction:InvokeServer(userId)
	end)

	if success and result then
		chatTagCache[userId] = {
			tag = result.tag,
			tagColor = result.tagColor,
			lastUpdate = now
		}
		return result.tag, result.tagColor
	end

	return nil, nil
end

-- Check if TextChatService is enabled
if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
	warn("[ChatTag Client] Legacy chat detected - chat tags not supported")
	return
end

-- Wait for ChatWindowConfiguration
local chatWindowConfiguration = TextChatService:WaitForChild("ChatWindowConfiguration", 5)
if not chatWindowConfiguration then
	warn("[ChatTag Client] ChatWindowConfiguration not found")
	return
end

-- Hook into TextChatService.OnIncomingMessage
TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local properties = chatWindowConfiguration:DeriveNewMessageProperties()

	-- Get player from message
	local textSource = message.TextSource
	if not textSource then
		return properties
	end

	-- Get chat tag from server
	local tag, tagColor = getChatTag(textSource.UserId)

	if tag and tagColor then
		-- Format: [Tag] with color + original prefix
		local tagHex = colorToHex(tagColor)
		properties.PrefixText = string.format('<font color="%s">[%s]</font> ', tagHex, tag) .. message.PrefixText
	end

	return properties
end

print("✅ ChatTagClient loaded!")
