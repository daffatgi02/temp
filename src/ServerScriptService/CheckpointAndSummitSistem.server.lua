-- Checkpoint and Summit System with ProfileStore Migration

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- ========================================
-- PROFILESTORE SETUP
-- ========================================
local ProfileStore = require(game.ServerScriptService.ProfileStore)

local PROFILE_TEMPLATE = {
	Summits = 0,
	Checkpoint = "Spawn",
}

local PlayerProfileStore = ProfileStore.New("PlayerDataV2_PS", PROFILE_TEMPLATE)
local Profiles = {} -- [player] = profile

-- ========================================
-- HD ADMIN INTEGRATION WITH RETRY
-- ========================================

local HDAdminMain = _G.HDAdminMain
local HD_ADMIN_READY = false

-- Wait for HD Admin with timeout
task.spawn(function()
	local attempts = 0
	local maxAttempts = 20 -- 10 seconds max

	while not HDAdminMain and attempts < maxAttempts do
		task.wait(0.5)
		HDAdminMain = _G.HDAdminMain
		attempts = attempts + 1
	end

	if HDAdminMain then
		HD_ADMIN_READY = true
		-- HD Admin connected and ready
	else
		-- HD Admin not found after 10 seconds - using fallback system
	end
end)

-- ========================================
-- CONFIGURATION CONSTANTS
-- ========================================

-- Checkpoint Configuration
local CP_COUNT = 12 -- total / jumlah cp
local CP_NAMES = {}
for i = 1, CP_COUNT do
	table.insert(CP_NAMES, "CP" .. i)
end

-- Summit Configuration
local SUMMITS_PER_COMPLETION = 100
local SUMMIT_DEBOUNCE_TIME = 1.0

-- UI Display Constants
local NAME_DISPLAY_WIDTH = 280
local NAME_DISPLAY_HEIGHT = 75
local NAME_DISPLAY_OFFSET = Vector3.new(0, 2.5, 0)
local NAME_DISPLAY_MAX_DISTANCE = 35
local LINE_HEIGHT_ROLE = 0.28
local LINE_HEIGHT_NAME = 0.42
local LINE_HEIGHT_INFO = 0.30
local ROLE_TEXT_SIZE = 14
local ROLE_TEXT_SIZE_LARGE = 20
local NAME_TEXT_SIZE = 28
local INFO_TEXT_SIZE = 14
local ICON_SIZE = 16

-- Custom Title Feature Toggle
local ENABLE_CUSTOM_TITLE = false

-- Checkpoint Notification Constants
local CP_NOTIFY_WIDTH = 420
local CP_NOTIFY_HEIGHT = 48
local CP_NOTIFY_DURATION = 2.6
local CP_NOTIFY_COOLDOWN = 0.8

-- ========================================
-- CRITICAL: PART REFERENCES
-- ========================================
local checkpointFolder = Workspace:FindFirstChild("cp")
local SummitPart = checkpointFolder and checkpointFolder:FindFirstChild("SummitPlate")
	or Workspace:FindFirstChild("SummitPlate")
local SpawnLocation = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChildOfClass("SpawnLocation")

-- 🔥 NEW: Track players who reached summit (for persistent spawn)
local playerAtSummit = {} -- [player] = true if at summit

-- ========================================
-- PLAYER CONFIGURATION (HYBRID SYSTEM)
-- ========================================

local PLAYER_CONFIG = {
	-- Owner
	[8978258458] = {
		role = "Owner",
		colorType = "rgb_wave",
		customTitle = nil, -- Custom title disabled / dimatikan
		verified = false,
		scripter = false,
		tiktoker = false,
	},
	-- HeadAdmins
	[9612593502] = {
		role = "HeadAdmin",
		colorType = "rgb_wave",
		customTitle = nil, -- Custom title disabled / dimatikan
		verified = true,
		scripter = false,
		tiktoker = false,
	},
	-- Admins king
	[9240638873] = {
		role = "Admin",
		colorType = "admin_red",
		customTitle = "ADMIN",
		verified = false,
		scripter = false,
		tiktoker = false,
	},

	-- Admins krispi
	[8825849958] = {
		role = "Admin",
		colorType = "admin_red",
		customTitle = "ADMIN",
		verified = false,
		scripter = false,
		tiktoker = false,
	},

	-- Admins juju
	[9118581801] = {
		role = "Admin",
		colorType = "admin_red",
		customTitle = "ADMIN",
		verified = false,
		scripter = false,
		tiktoker = false,
	},

	-- Admins anoj
	[9241659321] = {
		role = "Admin",
		colorType = "admin_red",
		customTitle = "ADMIN",
		verified = false,
		scripter = false,
		tiktoker = false,
	},

	--- nadhin
	[8222796361] = {
		role = "Admin",
		colorType = "admin_red",
		customTitle = "ADMIN",
		verified = false,
		scripter = false,
		tiktoker = false,
	},

	--- envy
	[9596985133] = {
		role = "Admin",
		colorType = "admin_red",
		customTitle = "ADMIN",
		verified = false,
		scripter = false,
		tiktoker = false,
	},

	--- UNTA
	[8807634689] = {
		role = "Admin",
		colorType = "admin_red",
		customTitle = "ADMIN",
		verified = false,
		scripter = false,
		tiktoker = false,
	},

	---macanstae
	[9065140275] = {
		role = "VIP",
		colorType = "vip_gold",
		customTitle = "PREMIUM",
		verified = false,
		scripter = false,
		tiktoker = false,
	},
	
	---dedut
	[9060107999] = {
		role = "VIP",
		colorType = "vip_gold",
		customTitle = "PREMIUM",
		verified = false,
		scripter = false,
		tiktoker = false,
	},

	---vincent
	[9176556789] = {
		role = "VIP",
		colorType = "vip_gold",
		customTitle = "PREMIUM",
		verified = false,
		scripter = false,
		tiktoker = false,
	},
}

-- EMOJI untuk setiap rank
local ROLE_EMOJI = {
	Owner = "👑",
	HeadAdmin = "",
	Admin = "🛡️",
	Mod = "⚔️",
	VIP = "⭐",
	NonAdmin = "",
}

-- Warna bracket untuk setiap rank
local ROLE_BRACKET_COLORS = {
	Owner = Color3.fromRGB(255, 215, 0),
	HeadAdmin = Color3.fromRGB(220, 20, 60),
	Admin = Color3.fromRGB(50, 205, 50),
	Mod = Color3.fromRGB(255, 140, 0),
	VIP = Color3.fromRGB(255, 215, 0),
	NonAdmin = Color3.fromRGB(200, 200, 200),
}

-- ========================================
-- STATE MANAGEMENT
-- ========================================

local playerCheckpoint = {}
local cpNotifyCooldown = {}
local summitDebounce = {}
local fallDebounce = {}

local playerAnimations = {}
local playerConnections = {}
local checkpointConnections = {}

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

local function getPlayerConfig(userId)
	return PLAYER_CONFIG[userId] or {}
end

-- GET RANK WITH HD ADMIN + FALLBACK (FIXED)
local function getPlayerRank(player)
	-- Try HD Admin first (if ready)
	if HD_ADMIN_READY and HDAdminMain then
		local success, result = pcall(function()
			-- HD Admin stores ranks in different ways, try multiple methods:

			-- Method 1: Check if rankings module exists
			if HDAdminMain.rankings then
				local rank = HDAdminMain.rankings:GetRank(player)
				if rank then
					return rank.Name or rank
				end
			end

			-- Method 2: Check player's Rank value
			local rankValue = player:FindFirstChild("Rank")
			if rankValue then
				return tostring(rankValue.Value)
			end

			-- Method 3: Try HD Admin's user module
			if HDAdminMain.user then
				local rankData = HDAdminMain.user.getRank(player)
				if rankData then
					return rankData
				end
			end

			return nil
		end)

		if success and result then
			return result
		end
	end

	-- Fallback to PLAYER_CONFIG
	local config = PLAYER_CONFIG[player.UserId]
	if config and config.role then
		return config.role
	end

	return nil
end

local function colorToHex(color)
	local r = math.floor(color.R * 255)
	local g = math.floor(color.G * 255)
	local b = math.floor(color.B * 255)
	return string.format("#%02X%02X%02X", r, g, b)
end

local function getCheckpointNumber(cpName)
	if not cpName or cpName == "Spawn" then
		return 0
	end
	if cpName == "Summit" then
		return 999
	end
	local number = cpName:match("CP(%d+)")
	return tonumber(number) or 0
end

local function getNextRequiredCheckpoint(player)
	local currentCP = playerCheckpoint[player]
	local currentNumber = getCheckpointNumber(currentCP)
	return "CP" .. (currentNumber + 1)
end

local function isValidCheckpoint(cpName)
	return table.find(CP_NAMES, cpName) ~= nil
end

local function hasCompletedAllCheckpoints(player)
	local currentCP = playerCheckpoint[player]
	local currentNumber = getCheckpointNumber(currentCP)
	local totalCheckpoints = #CP_NAMES
	return currentNumber >= totalCheckpoints
end

local function getMissingCheckpoint(player)
	local currentCP = playerCheckpoint[player]
	local currentNumber = getCheckpointNumber(currentCP)
	local totalCheckpoints = #CP_NAMES

	if currentNumber < totalCheckpoints then
		return "CP" .. (currentNumber + 1)
	end

	return nil
end

local function findCheckpointPart(cpName)
	if cpName == "Summit" then
		return SummitPart
	end

	if not checkpointFolder then
		-- Fallback: cari di Workspace langsung
		local cpPart = Workspace:FindFirstChild(cpName, true)
		if cpPart and cpPart:IsA("BasePart") then
			return cpPart
		end
		return nil
	end

	-- Method 1: Cari part dengan nama cpName (e.g., "CP1") di semua folder checkpoint
	for _, folder in ipairs(checkpointFolder:GetChildren()) do
		if folder:IsA("Folder") or folder:IsA("Model") then
			local cpPart = folder:FindFirstChild(cpName)
			if cpPart and cpPart:IsA("BasePart") then
				return cpPart
			end
		end
	end

	-- Method 2: Cari folder dengan nama cpName (backward compatibility)
	local cpModel = checkpointFolder:FindFirstChild(cpName)
	if cpModel then
		-- Cari part di dalam folder
		local areaCP = cpModel:FindFirstChild("AreaCP")
		if areaCP and areaCP:IsA("BasePart") then
			return areaCP
		end

		local areaBawah = cpModel:FindFirstChild("AreaBawahAuraCP")
		if areaBawah and areaBawah:IsA("BasePart") then
			return areaBawah
		end

		local pillar = cpModel:FindFirstChild("Pillar")
		if pillar and pillar:IsA("BasePart") then
			return pillar
		end

		if cpModel:IsA("BasePart") then
			return cpModel
		end
	end

	return nil
end

local function syncPlayerCheckpointEffects(player)
	local syncEvent = ReplicatedStorage:FindFirstChild("SyncCheckpointEffects")
	if not syncEvent then
		return
	end

	local currentCP = playerCheckpoint[player]
	local currentNumber = getCheckpointNumber(currentCP)

	syncEvent:FireClient(player, currentNumber)
end

-- ========================================
-- FALL DETECTION SYSTEM (CollectionService)
-- ========================================

local FALL_DEBOUNCE_TIME = 1.0

local function respawnAtLastCheckpoint(player)
	local character = player.Character
	if not character then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local lastCheckpoint = playerCheckpoint[player]

	-- If player is at summit, respawn at summit
	if playerAtSummit[player] and SummitPart then
		hrp.CFrame = SummitPart.CFrame + Vector3.new(0, 3, 0)
		return
	end

	-- If player has a checkpoint, respawn there
	if lastCheckpoint and lastCheckpoint ~= "Spawn" then
		local cpPart = findCheckpointPart(lastCheckpoint)
		if cpPart then
			hrp.CFrame = cpPart.CFrame + Vector3.new(0, 3, 0)
		else
			-- Fallback to spawn if checkpoint part not found
			if SpawnLocation then
				hrp.CFrame = CFrame.new(SpawnLocation.Position + Vector3.new(0, 3, 0))
			end
		end
	else
		-- Player is at spawn, respawn at spawn
		if SpawnLocation then
			hrp.CFrame = CFrame.new(SpawnLocation.Position + Vector3.new(0, 3, 0))
		end
	end
end

local function setupFallAreaDetection()
	-- Pastikan checkpointFolder ada
	if not checkpointFolder then
		warn("Checkpoint folder tidak ditemukan, fall detection tidak aktif")
		return
	end

	-- Loop melalui semua folder checkpoint
	for _, cpFolder in ipairs(checkpointFolder:GetChildren()) do
		if cpFolder:IsA("Folder") or cpFolder:IsA("Model") then
			-- Cari part CPFallArea di dalam folder ini
			local fallArea = cpFolder:FindFirstChild("CPFallArea")

			if fallArea and fallArea:IsA("BasePart") then
				-- Make fall area invisible and non-collidable
				fallArea.CanCollide = false
				fallArea.Transparency = 1

				-- Connect touch event
				fallArea.Touched:Connect(function(hit)
					local character = hit.Parent
					if not character then
						return
					end

					local player = Players:GetPlayerFromCharacter(character)
					if not player then
						return
					end

					-- Check debounce
					local now = os.clock()
					if fallDebounce[player] and (now - fallDebounce[player]) < FALL_DEBOUNCE_TIME then
						return
					end
					fallDebounce[player] = now

					-- Respawn at last checkpoint
					respawnAtLastCheckpoint(player)
				end)
			end
		end
	end

	-- Listen for new checkpoint folders being added (untuk support runtime addition)
	checkpointFolder.ChildAdded:Connect(function(cpFolder)
		task.wait(0.1) -- Tunggu sebentar untuk memastikan isi folder sudah loaded

		if cpFolder:IsA("Folder") or cpFolder:IsA("Model") then
			local fallArea = cpFolder:FindFirstChild("CPFallArea")

			if fallArea and fallArea:IsA("BasePart") then
				fallArea.CanCollide = false
				fallArea.Transparency = 1

				fallArea.Touched:Connect(function(hit)
					local character = hit.Parent
					if not character then
						return
					end

					local player = Players:GetPlayerFromCharacter(character)
					if not player then
						return
					end

					local now = os.clock()
					if fallDebounce[player] and (now - fallDebounce[player]) < FALL_DEBOUNCE_TIME then
						return
					end
					fallDebounce[player] = now

					respawnAtLastCheckpoint(player)
				end)
			end
		end
	end)
end

-- ========================================
-- CLEANUP FUNCTIONS
-- ========================================

local function cleanupPlayerAnimations(player)
	if playerAnimations[player] then
		for _, flag in ipairs(playerAnimations[player]) do
			if flag and flag.Value ~= nil then
				flag.Value = false
			end
		end
		playerAnimations[player] = nil
	end
end

local function cleanupPlayerConnections(player)
	if playerConnections[player] then
		for _, connection in ipairs(playerConnections[player]) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end
		playerConnections[player] = nil
	end
end

local function cleanupPlayer(player)
	cleanupPlayerAnimations(player)
	cleanupPlayerConnections(player)
	playerCheckpoint[player] = nil
	summitDebounce[player] = nil
	fallDebounce[player] = nil
end

local function cleanupAllCheckpointConnections()
	for cpName, connection in pairs(checkpointConnections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end
	checkpointConnections = {}
end

-- ========================================
-- COLOR ANIMATION SYSTEM
-- ========================================

local COLOR_ANIMATIONS = {
	pink_pulse = function(t)
		local intensity = (math.sin(t * 3) + 1) / 2
		return Color3.fromRGB(255, math.floor(150 + intensity * 105), math.floor(180 + intensity * 75))
	end,

	rainbow = function(t)
		local hue = (t * 0.5) % 1
		return Color3.fromHSV(hue, 1, 1)
	end,

	dark_pulse = function(t)
		local intensity = (math.sin(t * 2) + 1) / 2
		return Color3.fromRGB(
			math.floor(25 + intensity * 80),
			math.floor(25 + intensity * 80),
			math.floor(25 + intensity * 80)
		)
	end,

	fire = function(t)
		local phase = t * 4
		return Color3.fromRGB(
			255,
			math.floor(100 + (math.sin(phase) + 1) * 77.5),
			math.floor(0 + (math.sin(phase * 1.5) + 1) * 50)
		)
	end,

	ocean = function(t)
		local phase = t * 2.5
		return Color3.fromRGB(
			math.floor(0 + (math.sin(phase) + 1) * 100),
			math.floor(150 + (math.sin(phase * 1.2) + 1) * 52.5),
			255
		)
	end,

	electric = function(t)
		local phase = t * 6
		return Color3.fromRGB(
			math.floor(0 + (math.sin(phase) + 1) * 127.5),
			math.floor(200 + (math.sin(phase * 1.3) + 1) * 27.5),
			255
		)
	end,

	sakura = function(t)
		local phase = t * 1.8
		return Color3.fromRGB(
			255,
			math.floor(182 + (math.sin(phase) + 1) * 36.5),
			math.floor(193 + (math.sin(phase * 1.1) + 1) * 31)
		)
	end,

	forest = function(t)
		local phase = t * 2.2
		return Color3.fromRGB(
			math.floor(34 + (math.sin(phase) + 1) * 50),
			math.floor(139 + (math.sin(phase * 1.4) + 1) * 58),
			math.floor(34 + (math.sin(phase * 0.8) + 1) * 50)
		)
	end,

	black_maroon = function(t)
		local phase = t * 2.5
		local intensity = (math.sin(phase) + 1) / 2
		return Color3.fromRGB(
			math.floor(0 + intensity * 128),
			math.floor(0 + intensity * 30),
			math.floor(0 + intensity * 30)
		)
	end,

	red_pulse = function(t)
		local phase = t * 3.5
		local intensity = (math.sin(phase) + 1) / 2
		return Color3.fromRGB(255, math.floor(0 + intensity * 100), math.floor(0 + intensity * 100))
	end,

	random_chaos = function(t)
		local phase1, phase2, phase3 = t * 4.2, t * 3.7, t * 2.9
		return Color3.fromRGB(
			math.floor(128 + (math.sin(phase1) + 1) * 63.5),
			math.floor(128 + (math.sin(phase2) + 1) * 63.5),
			math.floor(128 + (math.sin(phase3) + 1) * 63.5)
		)
	end,

	developer_gradient = function(t)
		local phase = t * 3.0
		local cycle = (phase % 3) / 3

		if cycle < 0.33 then
			local progress = cycle / 0.33
			return Color3.fromRGB(math.floor(255 - progress * 155), math.floor(0 + progress * 255), 100)
		elseif cycle < 0.66 then
			local progress = (cycle - 0.33) / 0.33
			return Color3.fromRGB(100, math.floor(255 - progress * 155), math.floor(100 + progress * 155))
		else
			local progress = (cycle - 0.66) / 0.34
			return Color3.fromRGB(math.floor(100 + progress * 155), 0, math.floor(255 - progress * 155))
		end
	end,

	purple_galaxy = function(t)
		local phase = t * 2.8
		local cycle = (phase % 4) / 4

		if cycle < 0.25 then
			local progress = cycle / 0.25
			return Color3.fromRGB(
				math.floor(75 + progress * 130),
				math.floor(0 + progress * 50),
				math.floor(130 + progress * 125)
			)
		elseif cycle < 0.5 then
			local progress = (cycle - 0.25) / 0.25
			return Color3.fromRGB(
				math.floor(205 + progress * 50),
				math.floor(50 + progress * 155),
				math.floor(255 - progress * 105)
			)
		elseif cycle < 0.75 then
			local progress = (cycle - 0.5) / 0.25
			return Color3.fromRGB(
				math.floor(255 - progress * 117),
				math.floor(205 - progress * 162),
				math.floor(150 + progress * 76)
			)
		else
			local progress = (cycle - 0.75) / 0.25
			return Color3.fromRGB(
				math.floor(138 - progress * 63),
				math.floor(43 - progress * 43),
				math.floor(226 - progress * 96)
			)
		end
	end,

	black_random_rgb = function(t)
		local phase = t * 3.5
		local cycle = (phase % 4) / 4

		if cycle < 0.25 then
			local progress = cycle / 0.25
			return Color3.fromRGB(math.floor(0 + progress * 80), 0, 0)
		elseif cycle < 0.5 then
			local progress = (cycle - 0.25) / 0.25
			return Color3.fromRGB(math.floor(80 - progress * 80), math.floor(0 + progress * 80), 0)
		elseif cycle < 0.75 then
			local progress = (cycle - 0.5) / 0.25
			return Color3.fromRGB(0, math.floor(80 - progress * 80), math.floor(0 + progress * 80))
		else
			local progress = (cycle - 0.75) / 0.25
			return Color3.fromRGB(0, 0, math.floor(80 - progress * 80))
		end
	end,

	blue_rgb = function(t)
		local phase = t * 3.5
		local cycle = (phase % 3) / 3

		if cycle < 0.33 then
			local progress = cycle / 0.33
			return Color3.fromRGB(0, math.floor(0 + progress * 255), 255)
		elseif cycle < 0.66 then
			local progress = (cycle - 0.33) / 0.33
			return Color3.fromRGB(math.floor(0 + progress * 128), math.floor(255 - progress * 255), 255)
		else
			local progress = (cycle - 0.66) / 0.34
			return Color3.fromRGB(math.floor(128 - progress * 128), 0, 255)
		end
	end,

	red_rgb = function(t)
		local phase = t * 4.0
		local cycle = (phase % 3) / 3

		if cycle < 0.33 then
			local progress = cycle / 0.33
			return Color3.fromRGB(255, math.floor(0 + progress * 165), 0)
		elseif cycle < 0.66 then
			local progress = (cycle - 0.33) / 0.33
			return Color3.fromRGB(255, math.floor(165 + progress * 90), math.floor(0 + progress * 203))
		else
			local progress = (cycle - 0.66) / 0.34
			return Color3.fromRGB(255, math.floor(255 - progress * 255), math.floor(203 - progress * 203))
		end
	end,

	random_rgb_new_1 = function(t)
		local p1, p2, p3 = t * 4.5, t * 3.8, t * 5.2
		return Color3.fromRGB(
			math.floor(120 + (math.sin(p1) + 1) * 67.5),
			math.floor(120 + (math.sin(p2) + 1) * 67.5),
			math.floor(120 + (math.sin(p3) + 1) * 67.5)
		)
	end,

	random_rgb_new_2 = function(t)
		local p1, p2, p3 = t * 3.2, t * 4.7, t * 3.9
		return Color3.fromRGB(
			math.floor(100 + (math.sin(p1) + 1) * 77.5),
			math.floor(100 + (math.sin(p2) + 1) * 77.5),
			math.floor(100 + (math.sin(p3) + 1) * 77.5)
		)
	end,

	random_rgb_new_3 = function(t)
		local p1, p2, p3 = t * 5.8, t * 4.1, t * 6.2
		return Color3.fromRGB(
			math.floor(90 + (math.sin(p1) + 1) * 82.5),
			math.floor(90 + (math.sin(p2) + 1) * 82.5),
			math.floor(90 + (math.sin(p3) + 1) * 82.5)
		)
	end,

	random_rgb_new_4 = function(t)
		local p1, p2, p3 = t * 4.3, t * 5.1, t * 3.6
		return Color3.fromRGB(
			math.floor(110 + (math.sin(p1) + 1) * 72.5),
			math.floor(110 + (math.sin(p2) + 1) * 72.5),
			math.floor(110 + (math.sin(p3) + 1) * 72.5)
		)
	end,

	random_rgb_new_5 = function(t)
		local p1, p2, p3 = t * 3.7, t * 5.4, t * 4.8
		return Color3.fromRGB(
			math.floor(95 + (math.sin(p1) + 1) * 80),
			math.floor(95 + (math.sin(p2) + 1) * 80),
			math.floor(95 + (math.sin(p3) + 1) * 80)
		)
	end,

	random_rgb_new_6 = function(t)
		local p1, p2, p3 = t * 4.9, t * 3.4, t * 5.7
		return Color3.fromRGB(
			math.floor(105 + (math.sin(p1) + 1) * 75),
			math.floor(105 + (math.sin(p2) + 1) * 75),
			math.floor(105 + (math.sin(p3) + 1) * 75)
		)
	end,

	random_rgb_1 = function(t)
		local p1, p2, p3 = t * 3.8, t * 4.1, t * 3.5
		return Color3.fromRGB(
			math.floor(100 + (math.sin(p1) + 1) * 77.5),
			math.floor(100 + (math.sin(p2) + 1) * 77.5),
			math.floor(100 + (math.sin(p3) + 1) * 77.5)
		)
	end,

	random_rgb_2 = function(t)
		local p1, p2, p3 = t * 5.2, t * 4.8, t * 5.5
		return Color3.fromRGB(
			math.floor(80 + (math.sin(p1) + 1) * 87.5),
			math.floor(80 + (math.sin(p2) + 1) * 87.5),
			math.floor(80 + (math.sin(p3) + 1) * 87.5)
		)
	end,

	random_rgb_3 = function(t)
		local p1, p2, p3 = t * 4.7, t * 3.9, t * 5.1
		return Color3.fromRGB(
			math.floor(120 + (math.sin(p1) + 1) * 67.5),
			math.floor(120 + (math.sin(p2) + 1) * 67.5),
			math.floor(120 + (math.sin(p3) + 1) * 67.5)
		)
	end,

	owner_rainbow = function(t)
		local phase = t * 1.5
		local hue = (phase % 6) / 6
		return Color3.fromHSV(hue, 0.9, 1)
	end,

	-- ========================================
	-- RGB WAVE (Custom Rainbow)
	-- ========================================
	-- CUSTOMIZE SPEED: Ubah nilai 'speed' (2.7 = normal, 1.5 = lambat, 4.0 = cepat)
	-- CUSTOMIZE WAVE SPREAD: Ubah nilai 'step' (0.25 = normal, 0.4 = lebar, 0.1 = rapat)
	-- CUSTOMIZE COLORS: Ubah nilai RGB di setiap fase
	--   Fase 1: Red (255, 0, 0) -> Orange (255, 165, 0)
	--   Fase 2: Orange (255, 165, 0) -> Yellow (255, 255, 0)
	--   Fase 3: Yellow (255, 255, 0) -> Green (0, 255, 0)
	--   Fase 4: Green (0, 255, 0) -> Blue (0, 213, 255)
	--   Fase 5: Blue (0, 213, 255) -> Red (255, 0, 0) [loop]
	rgb_wave = function(t, charIndex, totalChars)
		local speed = 2.7 -- SPEED: Lower = slower/smoother, higher = faster
		local step = 0.25 -- WAVE SPREAD: Distance between character colors

		-- Calculate phase with delay per character (right to left)
		local phase = ((t * speed) + (charIndex * step)) % 5

		if phase < 1 then
			-- FASE 1: Red (255, 0, 0) -> Orange (255, 165, 0)
			local p = phase
			return Color3.fromRGB(255, math.floor(0 + (165 * p)), 0)
		elseif phase < 2 then
			-- FASE 2: Orange (255, 165, 0) -> Yellow (255, 255, 0)
			local p = phase - 1
			return Color3.fromRGB(255, math.floor(165 + (90 * p)), 0)
		elseif phase < 3 then
			-- FASE 3: Yellow (255, 255, 0) -> Green (0, 255, 0)
			local p = phase - 2
			return Color3.fromRGB(math.floor(255 - (255 * p)), 255, 0)
		elseif phase < 4 then
			-- FASE 4: Green (0, 255, 0) -> Blue (0, 213, 255)
			local p = phase - 3
			return Color3.fromRGB(0, math.floor(255 - (42 * p)), math.floor(0 + (255 * p)))
		else
			-- FASE 5: Blue (0, 213, 255) -> Red (255, 0, 0) [loop back]
			local p = phase - 4
			return Color3.fromRGB(math.floor(0 + (255 * p)), math.floor(213 - (213 * p)), math.floor(255 - (255 * p)))
		end
	end,
}

local function getAnimatedColor(colorType, time)
	local t = time or tick()
	local colorFunc = COLOR_ANIMATIONS[colorType]

	if colorFunc then
		return colorFunc(t)
	else
		local hue = (t * 0.8) % 1
		return Color3.fromHSV(hue, 0.8, 1)
	end
end

-- ========================================
-- TITLE SYSTEM
-- ========================================

local function getTitle(count)
	if count < 0 then
		return "❓ Summit Tidak Dikenal", Color3.fromRGB(128, 128, 128)
	elseif count >= 10000 then
		return "🌟 GOD", Color3.fromRGB(255, 215, 0)
	elseif count >= 8000 then
		return "⚡ Dewa", Color3.fromRGB(138, 43, 226)
	elseif count >= 6500 then
		return "🔥 Si Paling Pro", Color3.fromRGB(255, 69, 0)
	elseif count >= 5000 then
		return "❄️ Too EZ for me", Color3.fromRGB(0, 191, 255)
	elseif count >= 4000 then
		return "🌪️ Juara", Color3.fromRGB(70, 130, 180)
	elseif count >= 3500 then
		return "💎 Pendaki Elite", Color3.fromRGB(185, 242, 255)
	elseif count >= 3000 then
		return "🏆 Jago Mampus", Color3.fromRGB(255, 215, 0)
	elseif count >= 2500 then
		return "⚔️ Legendaris", Color3.fromRGB(255, 140, 0)
	elseif count >= 2000 then
		return "🗡️ Udah Gila", Color3.fromRGB(148, 0, 211)
	elseif count >= 1800 then
		return "🌀 Mendaki Tanpa Henti", Color3.fromRGB(75, 0, 130)
	elseif count >= 1600 then
		return "🔮 Master Summit", Color3.fromRGB(147, 112, 219)
	elseif count >= 1400 then
		return "⭐ Pendaki Langit", Color3.fromRGB(255, 255, 0)
	elseif count >= 1200 then
		return "🚀 Tak Terhentikan", Color3.fromRGB(0, 255, 255)
	elseif count >= 1000 then
		return "👑 Master", Color3.fromRGB(255, 215, 0)
	elseif count >= 100 then
		return "🏔️ Jago Banget", Color3.fromRGB(34, 139, 34)
	elseif count >= 50 then
		return "💪 Tryhard", Color3.fromRGB(255, 165, 0)
	elseif count >= 25 then
		return "🔥 Lumayan Jago", Color3.fromRGB(255, 69, 0)
	elseif count >= 10 then
		return "🗿 Pendaki Pemula", Color3.fromRGB(210, 180, 140)
	else
		return "🤡 Cupuh Banget", Color3.fromRGB(255, 255, 255)
	end
end

-- ========================================
-- ICON RETRIEVAL
-- ========================================

local function getIconFromTemplate(iconName)
	local NameTagTemplate = ReplicatedStorage:FindFirstChild("Tag")
	if NameTagTemplate then
		local iconsFrame = NameTagTemplate:FindFirstChild("IconsFrame")
		if iconsFrame then
			local icon = iconsFrame:FindFirstChild(iconName)
			if icon and icon:IsA("ImageLabel") then
				return icon.Image
			end
		end
	end
	return nil
end

-- ========================================
-- NAME DISPLAY SYSTEM
-- ========================================

local function cleanupOldDisplay(head, player)
	for _, gui in ipairs(head:GetChildren()) do
		if gui:IsA("BillboardGui") then
			gui:Destroy()
		end
	end

	if head.Parent and head.Parent:IsA("Model") then
		local humanoid = head.Parent:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end

	cleanupPlayerAnimations(player)
	cleanupPlayerConnections(player)
end

local function createMainContainer(head)
	local mainGui = Instance.new("BillboardGui")
	mainGui.Name = "MainDisplay"
	mainGui.Adornee = head
	mainGui.Size = UDim2.new(4, 0, 1, 0)
	mainGui.StudsOffset = Vector3.new(0, 2.5, 0)
	mainGui.AlwaysOnTop = false
	mainGui.MaxDistance = math.huge
	mainGui.LightInfluence = 0
	mainGui.Parent = head

	local container = Instance.new("Frame")
	container.Size = UDim2.new(2, 0, 1.2, 0)
	container.Position = UDim2.new(-0.5, 0, 0, 0)
	container.BackgroundTransparency = 1
	container.Parent = mainGui

	return mainGui, container
end

local function createRoleLine(container, player, role, customTitle, colorType)
	if not role then
		return nil
	end

	local line1 = Instance.new("TextLabel")
	line1.Name = "RoleLine"
	line1.Size = UDim2.new(1, 0, 0.55, 0)
	line1.Position = UDim2.new(0, 0, 0, -2)
	line1.BackgroundTransparency = 1
	line1.TextStrokeColor3 = Color3.new(0, 0, 0)
	line1.TextStrokeTransparency = 0
	line1.Font = Enum.Font.GothamBold
	line1.TextScaled = true
	line1.TextSize = ENABLE_CUSTOM_TITLE and ROLE_TEXT_SIZE or ROLE_TEXT_SIZE_LARGE
	line1.TextWrapped = true
	line1.RichText = true
	line1.TextXAlignment = Enum.TextXAlignment.Center
	line1.TextYAlignment = Enum.TextYAlignment.Center
	line1.Parent = container

	if ENABLE_CUSTOM_TITLE and customTitle and colorType then
		local isActive = Instance.new("BoolValue")
		isActive.Value = true
		playerAnimations[player] = playerAnimations[player] or {}
		table.insert(playerAnimations[player], isActive)

		task.spawn(function()
			while isActive.Value and line1 and line1.Parent do
				local currentTime = tick()
				local animatedColor = getAnimatedColor(colorType, currentTime)
				local roleText = string.format("[%s%s]", role, ROLE_EMOJI[role] or "")
				local roleBracketColor = ROLE_BRACKET_COLORS[role] or Color3.fromRGB(255, 255, 255)
				local roleBracketHex = colorToHex(roleBracketColor)
				local animatedHex = colorToHex(animatedColor)

				line1.Text = string.format(
					'<font color="%s">%s</font> <font color="%s">%s</font>',
					roleBracketHex,
					roleText,
					animatedHex,
					customTitle
				)

				task.wait(0.5)
			end
		end)
	elseif colorType == "rgb_wave" then
		-- RGB WAVE: Per-character coloring animation
		local isActive = Instance.new("BoolValue")
		isActive.Value = true
		playerAnimations[player] = playerAnimations[player] or {}
		table.insert(playerAnimations[player], isActive)

		task.spawn(function()
			while isActive.Value and line1 and line1.Parent do
				local currentTime = tick()
				local roleText = string.format("[%s%s]", role, ROLE_EMOJI[role] or "")
				local totalChars = utf8.len(roleText)

				-- Build per-character colored text
				local coloredText = ""
				local charIndex = 1
				for pos, code in utf8.codes(roleText) do
					local char = utf8.char(code)
					local charColor = COLOR_ANIMATIONS.rgb_wave(currentTime, charIndex, totalChars)
					local charHex = colorToHex(charColor)
					coloredText = coloredText .. string.format('<font color="%s">%s</font>', charHex, char)
					charIndex = charIndex + 1
				end

				line1.Text = coloredText
				task.wait(0.05) -- Faster update for smooth wave effect
			end
		end)
	elseif ENABLE_CUSTOM_TITLE and colorType == "owner_rainbow" then
		local isActive = Instance.new("BoolValue")
		isActive.Value = true
		playerAnimations[player] = playerAnimations[player] or {}
		table.insert(playerAnimations[player], isActive)

		task.spawn(function()
			while isActive.Value and line1 and line1.Parent do
				local currentTime = tick()
				local rainbowColor = getAnimatedColor("owner_rainbow", currentTime)
				local rainbowHex = colorToHex(rainbowColor)

				line1.Text = string.format('<font color="%s">[%s%s]</font>', rainbowHex, role, ROLE_EMOJI[role] or "")

				task.wait(0.5)
			end
		end)
	else
		line1.TextColor3 = ROLE_BRACKET_COLORS[role] or Color3.new(1, 1, 1)
		line1.Text = string.format("[%s%s]", role, ROLE_EMOJI[role] or "")
	end

	return line1
end

local function createNameLine(container, player, role, hasIcons)
	local line2Frame = Instance.new("Frame")
	line2Frame.Name = "NameLineFrame"
	line2Frame.Size = UDim2.new(1, 0, 0.35, 0)
	line2Frame.Position = UDim2.new(0, 0, 0.35, 0)
	line2Frame.BackgroundTransparency = 1
	line2Frame.Parent = container

	local line2 = Instance.new("TextLabel")
	line2.Name = "NameLine"
	if hasIcons then
		line2.Size = UDim2.new(0.65, 0, 1, 0)
		line2.Position = UDim2.new(0.05, 0, 0, 0)
	else
		line2.Size = UDim2.new(1, 0, 1, 0)
		line2.Position = UDim2.new(0, 0, 0, 0)
	end
	line2.BackgroundTransparency = 1
	line2.TextStrokeColor3 = Color3.new(0, 0, 0)
	line2.TextStrokeTransparency = 0
	line2.Font = Enum.Font.SourceSansBold
	line2.TextScaled = true
	line2.TextSize = NAME_TEXT_SIZE
	line2.TextWrapped = true
	line2.RichText = true
	line2.TextXAlignment = Enum.TextXAlignment.Center
	line2.TextYAlignment = Enum.TextYAlignment.Center
	line2.Parent = line2Frame

	local config = getPlayerConfig(player.UserId)
	local isPlayerVerified = config.verified == true
	local isPremium = player.MembershipType == Enum.MembershipType.Premium
	local displayName = player.DisplayName

	local function updateNameDisplay()
		local displayText = '<font color="#FFFFFF">' .. displayName .. "</font>"

		if isPremium then
			displayText = '<font color="#FFD700">' .. utf8.char(0xE001) .. "</font> " .. displayText
		end

		if isPlayerVerified then
			displayText = displayText .. ' <font color="#00BFFF">' .. utf8.char(0xE000) .. "</font>"
			line2.Text = displayText

			local isActive = Instance.new("BoolValue")
			isActive.Value = true
			playerAnimations[player] = playerAnimations[player] or {}
			table.insert(playerAnimations[player], isActive)

			task.spawn(function()
				while isActive.Value and line2 and line2.Parent do
					local time = (tick() % 4) / 4
					local rainbowColor = Color3.fromHSV(time, 1, 1)
					local rainbowHex = colorToHex(rainbowColor)

					local newText = '<font color="#FFFFFF">' .. displayName .. "</font>"
					if isPremium then
						newText = '<font color="#FFD700">' .. utf8.char(0xE001) .. "</font> " .. newText
					end
					newText = newText .. ' <font color="' .. rainbowHex .. '">' .. utf8.char(0xE000) .. "</font>"

					line2.Text = newText
					task.wait(0.15)
				end
			end)
		else
			line2.Text = displayText
		end
	end

	updateNameDisplay()

	if hasIcons then
		local isPlayerScripter = config.scripter == true
		local isPlayerTiktoker = config.tiktoker == true
		local iconCount = (isPlayerScripter and 1 or 0) + (isPlayerTiktoker and 1 or 0)

		if isPlayerScripter then
			local scripterImageId = getIconFromTemplate("ScripterIcon")
			if scripterImageId then
				local scripterIcon = Instance.new("ImageLabel")
				scripterIcon.Name = "ScripterIcon"
				scripterIcon.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
				local scripterPos = iconCount == 1 and 0.82 or 0.72
				scripterIcon.Position = UDim2.new(scripterPos, 0, 0.1, 0)
				scripterIcon.BackgroundTransparency = 1
				scripterIcon.Image = scripterImageId
				scripterIcon.ScaleType = Enum.ScaleType.Fit
				scripterIcon.Parent = line2Frame
			end
		end

		if isPlayerTiktoker then
			local tiktokerImageId = getIconFromTemplate("TiktokIcon")
			if tiktokerImageId then
				local tiktokerIcon = Instance.new("ImageLabel")
				tiktokerIcon.Name = "TiktokIcon"
				tiktokerIcon.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
				local tiktokerPos = isPlayerScripter and 0.84 or 0.82
				tiktokerIcon.Position = UDim2.new(tiktokerPos, 0, 0.1, 0)
				tiktokerIcon.BackgroundTransparency = 1
				tiktokerIcon.Image = tiktokerImageId
				tiktokerIcon.ScaleType = Enum.ScaleType.Fit
				tiktokerIcon.Parent = line2Frame
			end
		end
	end

	return line2Frame
end

local function createInfoLine(container, summits, role, player)
	local line3 = Instance.new("TextLabel")
	line3.Name = "InfoLine"
	line3.Size = UDim2.new(1, 0, 0.5, 0)
	line3.Position = UDim2.new(0, 0, 0.7, 0)
	line3.BackgroundTransparency = 1
	line3.TextStrokeColor3 = Color3.new(0, 0, 0)
	line3.TextStrokeTransparency = 0
	line3.Font = Enum.Font.SourceSansBold
	line3.TextScaled = true
	line3.TextSize = INFO_TEXT_SIZE
	line3.TextWrapped = true
	line3.RichText = true
	line3.TextXAlignment = Enum.TextXAlignment.Center
	line3.TextYAlignment = Enum.TextYAlignment.Center
	line3.Parent = container

	local function updateInfoLine(summitValue)
		local title, titleColor = getTitle(summitValue)
		local cleanTitle =
			title:gsub("🏔️ ", ""):gsub("👑 ", ""):gsub("🌟 ", ""):gsub("⚡ ", ""):gsub("🔥 ", "")
		local hexColor = colorToHex(titleColor)

		local stats = player:FindFirstChild("leaderstats")
		local checkpointVal = stats and stats:FindFirstChild("Checkpoint")
		local currentCP = checkpointVal and checkpointVal.Value or "Spawn"

		local cpDisplay = ""
		if currentCP == "Spawn" then
			cpDisplay = '<font color="#888888">📍 Spawn</font>'
		elseif currentCP == "Summit" then
			cpDisplay = '<font color="#FFD700">🏔️ At Summit</font>'
		else
			local cpNumber = getCheckpointNumber(currentCP)
			cpDisplay = '<font color="#00BFFF">🚩 ' .. cpNumber .. "/" .. CP_COUNT .. "</font>"
		end

		line3.Text = string.format(
			'<font color="%s">%s</font> | %s | <font color="#FFD700">🏔️ %d</font>',
			hexColor,
			cleanTitle,
			cpDisplay,
			summitValue
		)
	end

	updateInfoLine(summits.Value)

	local summitConnection = summits.Changed:Connect(function(newVal)
		updateInfoLine(newVal)
	end)

	playerConnections[player] = playerConnections[player] or {}
	table.insert(playerConnections[player], summitConnection)

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local checkpointVal = stats:FindFirstChild("Checkpoint")
		if checkpointVal then
			local checkpointConnection = checkpointVal.Changed:Connect(function()
				updateInfoLine(summits.Value)
			end)

			table.insert(playerConnections[player], checkpointConnection)
		end
	end

	return line3
end

local function createMinimalistDisplay(player, head, summits)
	cleanupOldDisplay(head, player)

	local mainGui, container = createMainContainer(head)

	local config = getPlayerConfig(player.UserId)

	task.wait(0.5)

	local role = getPlayerRank(player)
	local customTitle = config.customTitle
	local colorType = config.colorType
	local hasIcons = config.scripter == true or config.tiktoker == true

	playerAnimations[player] = playerAnimations[player] or {}
	playerConnections[player] = playerConnections[player] or {}

	createRoleLine(container, player, role, customTitle, colorType)
	createNameLine(container, player, role, hasIcons)
	createInfoLine(container, summits, role, player)
end

-- ========================================
-- NOTIFICATION OBJECT POOLING SYSTEM
-- ========================================

local NotificationPool = {}
NotificationPool.__index = NotificationPool

function NotificationPool.new(player, poolSize)
	local self = setmetatable({}, NotificationPool)
	self.player = player
	self.available = {}
	self.inUse = {}
	self.poolSize = poolSize or 3

	for i = 1, self.poolSize do
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "PooledNotification_" .. i
		screenGui.ResetOnSpawn = false
		screenGui.IgnoreGuiInset = true
		screenGui.Enabled = false

		local label = Instance.new("TextLabel")
		label.Name = "NotifyLabel"
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.TextStrokeTransparency = 0
		label.Font = Enum.Font.GothamBold
		label.TextSize = 16
		label.TextScaled = false
		label.TextXAlignment = Enum.TextXAlignment.Right
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Parent = screenGui

		table.insert(self.available, screenGui)
	end

	return self
end

function NotificationPool:Get()
	local gui = table.remove(self.available)

	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "TempNotification"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.Enabled = false

		local label = Instance.new("TextLabel")
		label.Name = "NotifyLabel"
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.TextStrokeTransparency = 0
		label.Font = Enum.Font.GothamBold
		label.TextSize = 16
		label.TextScaled = false
		label.TextXAlignment = Enum.TextXAlignment.Right
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Parent = gui
	end

	self.inUse[gui] = true
	return gui
end

function NotificationPool:Return(gui)
	if not gui or not gui.Parent then
		return
	end

	self.inUse[gui] = nil

	gui.Enabled = false
	gui.Parent = nil

	local label = gui:FindFirstChild("NotifyLabel")
	if label then
		label.Text = ""
		label.Size = UDim2.new(0, 0, 0, 0)
		label.Position = UDim2.new(0, 0, 0, 0)
		label.AnchorPoint = Vector2.new(0, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.TextStrokeTransparency = 0
	end

	if gui.Name:match("^PooledNotification_") then
		table.insert(self.available, gui)
	else
		gui:Destroy()
	end
end

function NotificationPool:Cleanup()
	for _, gui in ipairs(self.available) do
		if gui then
			gui:Destroy()
		end
	end
	for gui, _ in pairs(self.inUse) do
		if gui then
			gui:Destroy()
		end
	end
	self.available = {}
	self.inUse = {}
end

local playerNotificationPools = {}

local function getNotificationPool(player)
	if not playerNotificationPools[player] then
		playerNotificationPools[player] = NotificationPool.new(player, 3)
	end
	return playerNotificationPools[player]
end

Players.PlayerRemoving:Connect(function(player)
	if playerNotificationPools[player] then
		playerNotificationPools[player]:Cleanup()
		playerNotificationPools[player] = nil
	end
end)

-- ========================================
-- NOTIFICATIONS (OPTIMIZED WITH POOLING)
-- ========================================

local function showCheckpointNotification(player, cpName)
	local lastNotificationTime = cpNotifyCooldown[player]
	if type(lastNotificationTime) == "number" and (os.clock() - lastNotificationTime) < CP_NOTIFY_COOLDOWN then
		return
	end

	cpNotifyCooldown[player] = os.clock()

	local cpNumber = cpName:match("%d+") or cpName

	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	local pool = getNotificationPool(player)
	local screenGui = pool:Get()

	local label = screenGui:FindFirstChild("NotifyLabel")
	if label then
		label.Text = "Kamu telah menginjak CP" .. tostring(cpNumber)
		label.Size = UDim2.new(0, 300, 0, 30)
		label.AnchorPoint = Vector2.new(1, 0.5)
		label.Position = UDim2.new(1, -10, 0.5, 0)
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	end

	screenGui.Parent = playerGui
	screenGui.Enabled = true

	task.delay(CP_NOTIFY_DURATION, function()
		if screenGui and screenGui.Parent then
			pool:Return(screenGui)
		end
	end)
end

local function showSummitNotification(player, summitCount)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	local pool = getNotificationPool(player)
	local screenGui = pool:Get()

	local label = screenGui:FindFirstChild("NotifyLabel")
	if label then
		label.Text = "🏔️ SUMMIT! Total: " .. tostring(summitCount)
		label.Size = UDim2.new(0, 250, 0, 30)
		label.AnchorPoint = Vector2.new(1, 0.5)
		label.Position = UDim2.new(1, -10, 0.5, 0)
		label.TextColor3 = Color3.fromRGB(255, 215, 0)
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	end

	screenGui.Parent = playerGui
	screenGui.Enabled = true

	task.delay(3.5, function()
		if screenGui and screenGui.Parent then
			pool:Return(screenGui)
		end
	end)
end

local function showSkipWarningNotification(player, requiredCP, returnLocation)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	local pool = getNotificationPool(player)
	local screenGui = pool:Get()

	local label = screenGui:FindFirstChild("NotifyLabel")
	if label then
		local returnText = returnLocation == "Spawn" and "spawn" or returnLocation
		label.Text = "⚠️ Harus injak " .. requiredCP .. " dulu!"
		label.Size = UDim2.new(0, 300, 0, 30)
		label.AnchorPoint = Vector2.new(1, 0.5)
		label.Position = UDim2.new(1, -10, 0.5, 0)
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeColor3 = Color3.fromRGB(255, 0, 0)
	end

	screenGui.Parent = playerGui
	screenGui.Enabled = true

	task.delay(3, function()
		if screenGui and screenGui.Parent then
			pool:Return(screenGui)
		end
	end)
end

local function showSummitCheckpointWarning(player, missingCP, returnLocation)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	local pool = getNotificationPool(player)
	local screenGui = pool:Get()

	local label = screenGui:FindFirstChild("NotifyLabel")
	if label then
		label.Text = "🚫 Belum bisa summit! Harus injak " .. missingCP .. " dulu!"
		label.Size = UDim2.new(0, 350, 0, 30)
		label.AnchorPoint = Vector2.new(1, 0.5)
		label.Position = UDim2.new(1, -10, 0.5, 0)
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeColor3 = Color3.fromRGB(255, 0, 0)
	end

	screenGui.Parent = playerGui
	screenGui.Enabled = true

	task.delay(3.5, function()
		if screenGui and screenGui.Parent then
			pool:Return(screenGui)
		end
	end)
end

-- ========================================
-- PLAYER MANAGEMENT WITH PROFILESTORE
-- ========================================

Players.PlayerAdded:Connect(function(player)
	-- Start ProfileStore session
	local profile = PlayerProfileStore:StartSessionAsync(tostring(player.UserId), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile ~= nil then
		-- Add UserId for GDPR compliance
		profile:AddUserId(player.UserId)

		-- Reconcile profile data with template
		profile:Reconcile()

		-- Handle session end
		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil
			player:Kick("Profile session end - Please rejoin")
		end)

		-- Check if player is still in game
		if player.Parent == Players then
			Profiles[player] = profile

			-- Create leaderstats
			local stats = Instance.new("Folder")
			stats.Name = "leaderstats"
			stats.Parent = player

			local summits = Instance.new("IntValue")
			summits.Name = "Summits"
			summits.Value = profile.Data.Summits
			summits.Parent = stats

			local checkpointVal = Instance.new("StringValue")
			checkpointVal.Name = "Checkpoint"
			checkpointVal.Value = profile.Data.Checkpoint
			checkpointVal.Parent = stats

			-- Update playerCheckpoint state
			local loadedCP = profile.Data.Checkpoint
			playerCheckpoint[player] = loadedCP ~= "Spawn" and loadedCP or nil

			-- Track if player is at summit
			if loadedCP == "Summit" then
				playerAtSummit[player] = true
			end

			local summitClaimed = Instance.new("BoolValue")
			summitClaimed.Name = "SummitClaimed"
			summitClaimed.Value = false
			summitClaimed.Parent = player

			local summitedSession = Instance.new("BoolValue")
			summitedSession.Name = "SummitedThisSession"
			summitedSession.Value = false
			summitedSession.Parent = player

			-- Auto-save on summits change
			summits.Changed:Connect(function(newValue)
				if profile:IsActive() then
					profile.Data.Summits = newValue
				end
			end)

			-- Auto-save on checkpoint change
			checkpointVal.Changed:Connect(function(newValue)
				if profile:IsActive() then
					profile.Data.Checkpoint = newValue
				end
			end)

			-- Character spawning
			player.CharacterAdded:Connect(function(char)
				local hrp = char:WaitForChild("HumanoidRootPart", 3)
				if not hrp then
					return
				end

				local stats = player:FindFirstChild("leaderstats")
				local summitedSession = player:FindFirstChild("SummitedThisSession")
				local summitClaimed = player:FindFirstChild("SummitClaimed")
				local checkpointVal = stats and stats:FindFirstChild("Checkpoint")

				-- Spawn at Summit if player reached it
				if playerAtSummit[player] and checkpointVal and checkpointVal.Value == "Summit" then
					if SummitPart then
						hrp.CFrame = SummitPart.CFrame + Vector3.new(0, 3, 0)
						summitClaimed.Value = false
					else
						if SpawnLocation then
							hrp.CFrame = CFrame.new(SpawnLocation.Position + Vector3.new(0, 3, 0))
						end
					end
				elseif summitedSession and summitedSession.Value then
					playerCheckpoint[player] = nil
					if SpawnLocation then
						hrp.CFrame = CFrame.new(SpawnLocation.Position + Vector3.new(0, 3, 0))
					else
						hrp.CFrame = CFrame.new(0, 50, 0)
					end
					summitedSession.Value = false
					summitClaimed.Value = false
					if checkpointVal then
						checkpointVal.Value = "Spawn"
					end
				else
					local lastCP = playerCheckpoint[player]
					if lastCP then
						local cpPart = findCheckpointPart(lastCP)
						if cpPart then
							hrp.CFrame = cpPart.CFrame + Vector3.new(0, 3, 0)
						else
							if SpawnLocation then
								hrp.CFrame = CFrame.new(SpawnLocation.Position + Vector3.new(0, 3, 0))
							else
								hrp.CFrame = CFrame.new(0, 50, 0)
							end
						end
					else
						if SpawnLocation then
							hrp.CFrame = CFrame.new(SpawnLocation.Position + Vector3.new(0, 3, 0))
						else
							hrp.CFrame = CFrame.new(0, 50, 0)
						end
					end
					summitClaimed.Value = false
				end

				local head = char:FindFirstChild("Head")
				if head then
					createMinimalistDisplay(player, head, summits)
				end
				task.spawn(function()
					task.wait(1)
					syncPlayerCheckpointEffects(player)
				end)
			end)
		else
			profile:EndSession()
		end
	else
		player:Kick("Profile load fail - Please rejoin")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local profile = Profiles[player]
	if profile ~= nil then
		-- Save final state
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local summits = stats:FindFirstChild("Summits")
			if summits then
				profile.Data.Summits = summits.Value
			end

			local checkpointVal = stats:FindFirstChild("Checkpoint")
			local saveCP = checkpointVal and checkpointVal.Value or "Spawn"

			if playerAtSummit[player] then
				saveCP = "Summit"
			elseif playerCheckpoint[player] and table.find(CP_NAMES, playerCheckpoint[player]) then
				saveCP = playerCheckpoint[player]
			end

			profile.Data.Checkpoint = saveCP
		end

		profile:EndSession()
	end

	cleanupPlayer(player)
	cpNotifyCooldown[player] = nil
	playerAtSummit[player] = nil
	fallDebounce[player] = nil
end)

-- ========================================
-- CHECKPOINT SOUND SYSTEM
-- ========================================

local playCheckpointSoundRemote = ReplicatedStorage:FindFirstChild("PlayCheckpointSound")
if not playCheckpointSoundRemote then
	playCheckpointSoundRemote = Instance.new("RemoteEvent")
	playCheckpointSoundRemote.Name = "PlayCheckpointSound"
	playCheckpointSoundRemote.Parent = ReplicatedStorage
end

local playSummitSoundRemote = ReplicatedStorage:FindFirstChild("PlaySummitSound")
if not playSummitSoundRemote then
	playSummitSoundRemote = Instance.new("RemoteEvent")
	playSummitSoundRemote.Name = "PlaySummitSound"
	playSummitSoundRemote.Parent = ReplicatedStorage
end

-- ========================================
-- CHECKPOINT SYSTEM
-- ========================================

local checkpointTouchDebounce = {}
local CHECKPOINT_DEBOUNCE_TIME = 0.5

for _, cpName in ipairs(CP_NAMES) do
	local part = findCheckpointPart(cpName)
	if part then
		local connection = part.Touched:Connect(function(hit)
			local char = hit.Parent
			if not char then
				return
			end
			local player = Players:GetPlayerFromCharacter(char)
			if not player then
				return
			end

			local now = os.clock()
			if
				checkpointTouchDebounce[player]
				and (now - checkpointTouchDebounce[player]) < CHECKPOINT_DEBOUNCE_TIME
			then
				return
			end
			checkpointTouchDebounce[player] = now

			if playerAtSummit[player] then
				return
			end

			local stats = player:FindFirstChild("leaderstats")
			local summitedSession = player:FindFirstChild("SummitedThisSession")

			-- Checkpoint touch logic - allow if not at summit and not in summit session
			local canTouch = not summitedSession or not summitedSession.Value

			if canTouch then
				local currentCheckpoint = playerCheckpoint[player]

				if currentCheckpoint == cpName then
					return
				end

				local currentCPNumber = getCheckpointNumber(currentCheckpoint)
				local touchedCPNumber = getCheckpointNumber(cpName)

				if touchedCPNumber < currentCPNumber then
					return
				end

				local nextRequiredCP = getNextRequiredCheckpoint(player)
				local requiredCPNumber = getCheckpointNumber(nextRequiredCP)

				if touchedCPNumber > requiredCPNumber then
					local lastCheckpoint = playerCheckpoint[player]
					local returnLocation = "Spawn"

					local hrp = char:FindFirstChild("HumanoidRootPart")

					if hrp then
						if lastCheckpoint and lastCheckpoint ~= "Spawn" then
							local lastCPPart = findCheckpointPart(lastCheckpoint)
							if lastCPPart then
								hrp.CFrame = lastCPPart.CFrame + Vector3.new(0, 3, 0)
								returnLocation = lastCheckpoint
							else
								if SpawnLocation then
									hrp.CFrame = CFrame.new(SpawnLocation.Position + Vector3.new(0, 3, 0))
								end
							end
						else
							if SpawnLocation then
								hrp.CFrame = CFrame.new(SpawnLocation.Position + Vector3.new(0, 3, 0))
							end
						end
					end

					showSkipWarningNotification(player, nextRequiredCP, returnLocation)
					return
				end

				-- Valid checkpoint progression
				playerCheckpoint[player] = cpName
				local checkpointVal = stats and stats:FindFirstChild("Checkpoint")
				if checkpointVal then
					checkpointVal.Value = cpName
				end

				task.spawn(function()
					syncPlayerCheckpointEffects(player)
				end)

				-- Play checkpoint sound (only for this player)
				pcall(function()
					playCheckpointSoundRemote:FireClient(player)
				end)

				pcall(function()
					showCheckpointNotification(player, cpName)
				end)
			end
		end)

		checkpointConnections[cpName] = connection
	end
end

-- ========================================
-- SUMMIT SYSTEM
-- ========================================

if SummitPart then
	local summitConnection = SummitPart.Touched:Connect(function(hit)
		local char = hit.Parent
		if not char then
			return
		end
		local player = Players:GetPlayerFromCharacter(char)
		if not player then
			return
		end

		if playerAtSummit[player] then
			return
		end

		local stats = player:FindFirstChild("leaderstats")
		local summitClaimed = player:FindFirstChild("SummitClaimed")
		local summitedSession = player:FindFirstChild("SummitedThisSession")
		local summits = stats and stats:FindFirstChild("Summits")

		if summitClaimed and summits and summitedSession then
			if summitClaimed.Value or summitDebounce[player] then
				return
			end

			if not hasCompletedAllCheckpoints(player) then
				local missingCP = getMissingCheckpoint(player)
				local lastCheckpoint = playerCheckpoint[player]

				showSummitCheckpointWarning(player, missingCP, lastCheckpoint or "Spawn")

				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					if lastCheckpoint and lastCheckpoint ~= "Spawn" then
						local lastCPPart = findCheckpointPart(lastCheckpoint)
						if lastCPPart then
							hrp.CFrame = lastCPPart.CFrame + Vector3.new(0, 3, 0)
						else
							if SpawnLocation then
								hrp.CFrame = CFrame.new(SpawnLocation.Position + Vector3.new(0, 3, 0))
							end
						end
					else
						if SpawnLocation then
							hrp.CFrame = CFrame.new(SpawnLocation.Position + Vector3.new(0, 3, 0))
						end
					end
				end

				return
			end

			summitDebounce[player] = true

			summits.Value = summits.Value + SUMMITS_PER_COMPLETION
			summitClaimed.Value = true
			summitedSession.Value = true

			playerCheckpoint[player] = "Summit"
			playerAtSummit[player] = true

			task.spawn(function()
				syncPlayerCheckpointEffects(player)
			end)

			local checkpointVal = stats:FindFirstChild("Checkpoint")
			if checkpointVal then
				checkpointVal.Value = "Summit"
			end

			-- Play summit sound (only for this player)
			pcall(function()
				playSummitSoundRemote:FireClient(player)
			end)

			showSummitNotification(player, summits.Value)

			task.delay(SUMMIT_DEBOUNCE_TIME, function()
				summitDebounce[player] = nil
			end)
		end
	end)

	checkpointConnections["Summit"] = summitConnection
end

-- ========================================
-- TEXTCHAT SERVICE - REPLICATE PLAYER CONFIG TO CLIENT
-- ========================================

local getPlayerConfigRemote = ReplicatedStorage:FindFirstChild("GetPlayerConfig")
if not getPlayerConfigRemote then
	getPlayerConfigRemote = Instance.new("RemoteFunction")
	getPlayerConfigRemote.Name = "GetPlayerConfig"
	getPlayerConfigRemote.Parent = ReplicatedStorage
end

getPlayerConfigRemote.OnServerInvoke = function(requestingPlayer, targetUserId)
	if type(targetUserId) ~= "number" then
		return nil
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		return nil
	end

	local config = getPlayerConfig(targetUserId)
	local role = getPlayerRank(targetPlayer)

	if not role then
		return nil
	end

	return {
		role = role,
		customTitle = config.customTitle,
		colorType = config.colorType,
		roleEmoji = ROLE_EMOJI[role],
		roleColor = ROLE_BRACKET_COLORS[role],
	}
end

-- ========================================
-- HD ADMIN API (EXPANDED)
-- ========================================

_G.SummitSystem = {
	GetSummits = function(player)
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local summits = stats:FindFirstChild("Summits")
			if summits then
				return summits.Value
			end
		end
		return 0
	end,

	SetSummits = function(player, amount)
		if type(amount) ~= "number" or amount < 0 or amount > 100000 then
			return false, "Invalid amount (0-100000)"
		end

		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local summits = stats:FindFirstChild("Summits")
			if summits then
				summits.Value = math.floor(amount)
				return true
			end
		end
		return false, "Leaderstats not found"
	end,

	GetCheckpoint = function(player)
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local checkpointVal = stats:FindFirstChild("Checkpoint")
			if checkpointVal then
				return checkpointVal.Value
			end
		end
		return "Spawn"
	end,

	SetCheckpoint = function(player, cpName)
		if cpName ~= "Spawn" and not table.find(CP_NAMES, cpName) then
			return false, "Invalid checkpoint name"
		end

		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local checkpointVal = stats:FindFirstChild("Checkpoint")
			if checkpointVal then
				checkpointVal.Value = cpName
				playerCheckpoint[player] = cpName ~= "Spawn" and cpName or nil

				-- Reset summit flag jika bukan Summit
				if cpName ~= "Summit" then
					playerAtSummit[player] = false

					local summitClaimed = player:FindFirstChild("SummitClaimed")
					if summitClaimed then
						summitClaimed.Value = false
					end

					local summitedSession = player:FindFirstChild("SummitedThisSession")
					if summitedSession then
						summitedSession.Value = false
					end
				else
					playerAtSummit[player] = true
				end

				task.spawn(function()
					syncPlayerCheckpointEffects(player)
				end)

				return true
			end
		end
		return false, "Leaderstats not found"
	end,

	GiveNextCheckpoint = function(player)
		local currentCP = playerCheckpoint[player]
		local currentNumber = getCheckpointNumber(currentCP)

		if currentNumber >= #CP_NAMES then
			return false, "Already at last checkpoint"
		end

		local nextCP = "CP" .. (currentNumber + 1)
		local success, err = _G.SummitSystem.SetCheckpoint(player, nextCP)

		if success then
			return true
		else
			return false, err
		end
	end,

	TeleportToCheckpoint = function(player, cpName)
		local char = player.Character
		if not char then
			return false, "Character not found"
		end

		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return false, "HumanoidRootPart not found"
		end

		local cpPart
		if cpName == "Spawn" then
			cpPart = SpawnLocation
		elseif cpName == "Summit" then
			cpPart = SummitPart
		else
			cpPart = findCheckpointPart(cpName)
		end

		if cpPart then
			hrp.CFrame = cpPart.CFrame + Vector3.new(0, 3, 0)

			-- Update playerAtSummit flag berdasarkan checkpoint
			if cpName == "Summit" then
				playerAtSummit[player] = true
			else
				playerAtSummit[player] = false
			end

			return true
		else
			return false, "Checkpoint part not found: " .. cpName
		end
	end,

	GetCheckpointList = function()
		local list = { "Spawn" }
		for _, cpName in ipairs(CP_NAMES) do
			table.insert(list, cpName)
		end
		return list
	end,

	AddSummits = function(player, delta)
		local current = _G.SummitSystem.GetSummits(player)
		local newAmount = current + delta

		newAmount = math.max(0, math.min(100000, newAmount))

		return _G.SummitSystem.SetSummits(player, newAmount)
	end,
}

-- ========================================
-- RESET TO BASECAMP SYSTEM
-- ========================================

local resetToBasecampRemote = ReplicatedStorage:FindFirstChild("ResetToBasecamp")
if not resetToBasecampRemote then
	resetToBasecampRemote = Instance.new("RemoteEvent")
	resetToBasecampRemote.Name = "ResetToBasecamp"
	resetToBasecampRemote.Parent = ReplicatedStorage
end

local checkSummitStatusRemote = ReplicatedStorage:FindFirstChild("CheckSummitStatus")
if not checkSummitStatusRemote then
	checkSummitStatusRemote = Instance.new("RemoteFunction")
	checkSummitStatusRemote.Name = "CheckSummitStatus"
	checkSummitStatusRemote.Parent = ReplicatedStorage
end

checkSummitStatusRemote.OnServerInvoke = function(player)
	return playerAtSummit[player] == true
end

resetToBasecampRemote.OnServerEvent:Connect(function(player)
	if not playerAtSummit[player] then
		return
	end

	playerCheckpoint[player] = nil
	playerAtSummit[player] = false

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local checkpointVal = stats:FindFirstChild("Checkpoint")
		if checkpointVal then
			checkpointVal.Value = "Spawn"
		end
	end

	local summitClaimed = player:FindFirstChild("SummitClaimed")
	if summitClaimed then
		summitClaimed.Value = false
	end

	local summitedSession = player:FindFirstChild("SummitedThisSession")
	if summitedSession then
		summitedSession.Value = false
	end

	local character = player.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp and SpawnLocation then
			hrp.CFrame = CFrame.new(SpawnLocation.Position + Vector3.new(0, 3, 0))
		end
	end

	task.spawn(function()
		syncPlayerCheckpointEffects(player)
	end)
end)

-- ========================================
-- SHUTDOWN CLEANUP
-- ========================================

game:BindToClose(function()
	-- Cleanup animations
	for player, _ in pairs(playerAnimations) do
		cleanupPlayer(player)
	end

	cleanupAllCheckpointConnections()

	-- End all profile sessions
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = Profiles[player]
		if profile ~= nil then
			local stats = player:FindFirstChild("leaderstats")
			if stats then
				local summits = stats:FindFirstChild("Summits")
				if summits then
					profile.Data.Summits = summits.Value
				end

				local checkpointVal = stats:FindFirstChild("Checkpoint")
				local saveCP = checkpointVal and checkpointVal.Value or "Spawn"

				if playerAtSummit[player] then
					saveCP = "Summit"
				elseif playerCheckpoint[player] and table.find(CP_NAMES, playerCheckpoint[player]) then
					saveCP = playerCheckpoint[player]
				end

				profile.Data.Checkpoint = saveCP
			end

			profile:EndSession()
		end
	end

	task.wait(3)
end)

-- ========================================
-- INITIALIZE FALL DETECTION SYSTEM
-- ========================================

setupFallAreaDetection()

-- Summit System with ProfileStore loaded
