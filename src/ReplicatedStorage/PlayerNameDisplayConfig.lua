-- ========================================
-- PLAYER NAME DISPLAY CONFIGURATION
-- ========================================
-- Simple configuration for chat tags only

local Config = {}

-- ========================================
-- PLAYER CONFIGURATION (ADMIN ROLES)
-- ========================================
-- Manually copy-paste admin UserIds from HD Admin Settings.lua
-- Format: [UserId] = { role = "RankName" }

Config.Players = {
	-- Owner (Rank 5)
	[8978258458] = { role = "Owner" },

	-- HeadAdmin (Rank 4)
	[9612593502] = { role = "HeadAdmin" },

	-- Admin (Rank 3)
	[9240638873] = { role = "Admin" },
	[9118581801] = { role = "Admin" },
	[9241659321] = { role = "Admin" },
	[8222796361] = { role = "Admin" },
	[8825849958] = { role = "Admin" },
	[8807634689] = { role = "Admin" },
	[9596985133] = { role = "Admin" },

	-- VIP (Rank 1)
	[9065140275] = { role = "VIP" },
	[9176556789] = { role = "VIP" },
}

-- ========================================
-- ROLE STYLING FOR CHAT
-- ========================================

-- Emoji for each rank (shown in chat tag)
Config.RoleEmojis = {
	Owner = "👑",
	HeadAdmin = "🛡️",
	Admin = "⚔️",
	Mod = "⚔️",
	VIP = "⭐",
}

-- Bracket color for each rank (chat tag color)
Config.RoleBracketColors = {
	Owner = Color3.fromRGB(255, 105, 180), -- Pink
	HeadAdmin = Color3.fromRGB(255, 105, 180), -- Pink
	Admin = Color3.fromRGB(255, 105, 180), -- Pink
	Mod = Color3.fromRGB(255, 105, 180), -- Pink
	VIP = Color3.fromRGB(255, 105, 180), -- Pink
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Get player configuration by UserId
function Config.GetPlayerConfig(userId)
	return Config.Players[userId] or {}
end

-- Check if player has custom configuration
function Config.HasCustomConfig(userId)
	return Config.Players[userId] ~= nil
end

return Config
