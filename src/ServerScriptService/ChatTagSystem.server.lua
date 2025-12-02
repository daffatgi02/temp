-- Chat Tag System
-- Manages chat tags for admins and players based on summit count

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("PlayerNameDisplayConfig"))

local playerChatData = {}

local function getChatTitle(count)
	local title, color
	if count < 0 then
		title, color = "Summit Tidak Dikenal", Color3.fromRGB(128, 128, 128)
	elseif count >= 10000 then
		title, color = "GOD", Color3.fromRGB(255, 105, 180) -- Pink
	elseif count >= 8000 then
		title, color = "Dewa", Color3.fromRGB(138, 43, 226) -- Purple
	elseif count >= 6500 then
		title, color = "Si Paling Pro", Color3.fromRGB(255, 69, 0) -- Red-Orange
	elseif count >= 5000 then
		title, color = "Too EZ for me", Color3.fromRGB(0, 191, 255) -- Deep Sky Blue
	elseif count >= 4000 then
		title, color = "Juara", Color3.fromRGB(70, 130, 180) -- Steel Blue
	elseif count >= 3500 then
		title, color = "Pendaki Elite", Color3.fromRGB(185, 242, 255) -- Light Blue
	elseif count >= 3000 then
		title, color = "Jago Mampus", Color3.fromRGB(255, 140, 0) -- Dark Orange
	elseif count >= 2500 then
		title, color = "Legendaris", Color3.fromRGB(255, 69, 0) -- Red-Orange
	elseif count >= 2000 then
		title, color = "Udah Gila", Color3.fromRGB(148, 0, 211) -- Dark Violet
	elseif count >= 1800 then
		title, color = "Mendaki Tanpa Henti", Color3.fromRGB(75, 0, 130) -- Indigo
	elseif count >= 1600 then
		title, color = "Master Summit", Color3.fromRGB(147, 112, 219) -- Medium Purple
	elseif count >= 1400 then
		title, color = "Pendaki Langit", Color3.fromRGB(255, 20, 147) -- Deep Pink
	elseif count >= 1200 then
		title, color = "Tak Terhentikan", Color3.fromRGB(0, 255, 255) -- Cyan
	elseif count >= 1000 then
		title, color = "Master", Color3.fromRGB(255, 165, 0) -- Orange
	elseif count >= 100 then
		title, color = "Jago Banget", Color3.fromRGB(34, 139, 34) -- Forest Green
	elseif count >= 50 then
		title, color = "Tryhard", Color3.fromRGB(255, 140, 0) -- Dark Orange
	elseif count >= 25 then
		title, color = "Lumayan Jago", Color3.fromRGB(255, 69, 0) -- Red-Orange
	elseif count >= 10 then
		title, color = "Pendaki Pemula", Color3.fromRGB(210, 180, 140) -- Tan
	else
		title, color = "NOOB", Color3.fromRGB(200, 200, 200) -- Light Gray
	end

	return title, color
end

-- RemoteFunction for client to get chat tag data
local getChatTagFunction = Instance.new("RemoteFunction")
getChatTagFunction.Name = "GetChatTagData"
getChatTagFunction.Parent = ReplicatedStorage

getChatTagFunction.OnServerInvoke = function(player, targetUserId)
	return playerChatData[targetUserId]
end

local function initializePlayer(player)
	-- Wait for leaderstats
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		return
	end

	local summitValue = leaderstats:FindFirstChild("Summits")
	if not summitValue then
		return
	end

	-- Get player config for admin role
	local playerConfig = Config.GetPlayerConfig(player.UserId)
	local role = playerConfig.role

	local function updatePlayerChatData()
		local tag, tagColor

		-- ADMIN: Priority tinggi, gunakan role sebagai tag
		if role then
			-- Admin tag dengan emoji dari config
			local emoji = Config.RoleEmojis[role] or ""
			tag = role .. emoji
			tagColor = Config.RoleBracketColors[role] or Color3.fromRGB(255, 215, 0)
		else
			-- PLAYER BIASA: Gunakan title berdasarkan summit count
			local title, color = getChatTitle(summitValue.Value)
			tag = title
			tagColor = color
		end

		-- Store in cache
		playerChatData[player.UserId] = {
			tag = tag,
			tagColor = tagColor
		}
	end

	-- Initial setup
	updatePlayerChatData()

	-- Update tag when summit count changes (only for non-admin)
	if not role then
		summitValue.Changed:Connect(function()
			updatePlayerChatData()
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		initializePlayer(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Cleanup
	playerChatData[player.UserId] = nil
end)

-- Setup for existing players
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		initializePlayer(player)
	end)
end

print("✅ ChatTagSystem loaded!")
