-- Dual-location Global Leaderboard 

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")
local Workspace = game:GetService("Workspace")

-- ========================================
-- CONFIGURATION CONSTANTS
-- ========================================

-- DataStore Configuration
local DS_RETRY_ATTEMPTS = 3
local DS_RETRY_DELAYS = {0.1, 0.3, 0.9}

-- Leaderboard Configuration
local LEADERBOARD_SIZE = 20
local UPDATE_INTERVAL = 45
local BASECAMP_BOARD_NAME = "GlobalLeaderboardPart"
local SUMMIT_MODEL_NAME = "SummitLeaderboardModel"
local SUMMIT_BOARD_NAME = "SummitLeaderboardPart"
local SUMMIT_AVATAR_MODEL_NAME = "SummitFirstPlaceAvatar"
local MAX_DISTANCE = 250

-- UI Layout Constants
local UI_CORNER_RADIUS_TOP3 = 15
local UI_CORNER_RADIUS_NORMAL = 12
local UI_BORDER_THICKNESS_TOP3 = 4
local UI_BORDER_THICKNESS_NORMAL = 3
local UI_PIXELS_PER_STUD = 55
local UI_LIST_PADDING = 15
local UI_TOP_PADDING = 25
local UI_CANVAS_EXTRA_SPACE = 150
local UI_ENTRY_HEIGHT = 95
local UI_ENTRY_WIDTH_SCALE = 0.95

-- Animation Constants
local ANIM_FADE_DURATION = 0.4
local ANIM_SLIDE_DURATION = 0.8
local ANIM_SIZE_DURATION = 0.6
local ANIM_GLOW_DURATION = 2.0
local ANIM_GRADIENT_ROTATION_DURATION = 8.0

-- Data Reset Window
local RESET_IGNORE_WINDOW = 60

-- ========================================
-- DATASTORE SETUP (MIGRATED TO PROFILESTORE NAMING)
-- ========================================

-- OrderedDataStore tetap digunakan untuk ranking (ProfileStore tidak support sorting)
local globalSummitStore = DataStoreService:GetOrderedDataStore("GlobalSummitLeaderboardV2_PS")
-- playerDataStore dihapus karena data summit sudah dikelola oleh ProfileStore di CheckpointSystem
local persistentDataStore = DataStoreService:GetDataStore("PersistentGlobalSummitsV2_PS")

-- ========================================
-- STAFF CONFIGURATION
-- ========================================

local EXCLUDED_STAFF = {
	[222222222222222] = true,
}

local ROLES = {
	Owner = {},
	HeadAdmin = {},
	Admin = {},
	Helper = {}
}

local ROLE_EMOJI = {
	Owner = "👑",
	HeadAdmin = "🛡️",
	Admin = "🛡️",
	Helper = "🤝"
}

-- ========================================
-- PRE-DEFINED GRADIENT COLOR SEQUENCES
-- ========================================

local GRADIENT_PURPLE_GLOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(138, 43, 226))
})

local GRADIENT_PURPLE_HEADER = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 0, 255)),
	ColorSequenceKeypoint.new(0.66, Color3.fromRGB(100, 20, 180)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(138, 43, 226))
})

local GRADIENT_MAIN_FRAME = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 15)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(25, 25, 35)),
	ColorSequenceKeypoint.new(0.66, Color3.fromRGB(15, 15, 25)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 40))
})

local GRADIENT_RANK1 = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 20, 180))
})

local GRADIENT_RANK2 = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 130, 180)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 149, 237)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 100, 150))
})

local GRADIENT_RANK3 = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(205, 127, 50)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 165, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 100, 30))
})

local GRADIENT_RANK_TOP10 = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 80)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 80, 100)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 50, 70))
})

local GRADIENT_RANK_NORMAL = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 50)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 50, 60)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 45))
})

-- ========================================
-- STATE MANAGEMENT
-- ========================================

local globalLeaderboardData = {}
local basecampSurfaceGui = nil
local basecampListContainer = nil
local summitSurfaceGui = nil
local summitListContainer = nil
local summitAvatarModule = nil -- BARU: Module untuk avatar
local basecampPosition = Vector3.new(0, 10, -50)
local summitPosition = Vector3.new(100, 50, 0)

local activeAnimations = {}
local activeConnections = {}
local isUpdatingDisplay = false
local lastSavedSummits = {}

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

local function isExcludedStaff(userId)
	return EXCLUDED_STAFF[userId] ~= nil
end

local function getPlayerRole(userId)
	for role, ids in pairs(ROLES) do
		if ids[userId] then return role end
	end
	return nil
end

-- ========================================
-- DATASTORE FUNCTIONS 
-- ========================================

local function safeUpdateAsync(store, key, transformFunction)
	for attempt = 1, DS_RETRY_ATTEMPTS do
		local success, result = pcall(function()
			return store:UpdateAsync(key, transformFunction)
		end)

		if success then
			return true, result
		end

		warn(("[DS] UpdateAsync failed (attempt %d/%d) for key=%s: %s"):format(
			attempt, DS_RETRY_ATTEMPTS, tostring(key), tostring(result)
			))

		if attempt < DS_RETRY_ATTEMPTS then
			task.wait(DS_RETRY_DELAYS[attempt])
		end
	end

	return false, nil
end

local function safeSetAsync(store, key, value)
	for attempt = 1, DS_RETRY_ATTEMPTS do
		local success, err = pcall(function()
			store:SetAsync(key, value)
		end)

		if success then
			return true
		end

		warn(("[DS] SetAsync failed (attempt %d/%d) for key=%s: %s"):format(
			attempt, DS_RETRY_ATTEMPTS, tostring(key), tostring(err)
			))

		if attempt < DS_RETRY_ATTEMPTS then
			task.wait(DS_RETRY_DELAYS[attempt])
		end
	end

	return false
end

local function safeGetAsync(store, key)
	for attempt = 1, DS_RETRY_ATTEMPTS do
		local success, result = pcall(function()
			return store:GetAsync(key)
		end)

		if success then
			return result
		end

		warn(("[DS] GetAsync failed (attempt %d/%d) for key=%s"):format(
			attempt, DS_RETRY_ATTEMPTS, tostring(key)
			))

		if attempt < DS_RETRY_ATTEMPTS then
			task.wait(DS_RETRY_DELAYS[attempt])
		end
	end

	return nil
end

local function smartSaveToGlobalStore(player, actualSummits)
	if isExcludedStaff(player.UserId) then
		return
	end

	if lastSavedSummits[player.UserId] == actualSummits then
		return
	end

	local playerData = {
		name = player.Name,
		summits = actualSummits,
		lastSeen = tick(),
		userId = player.UserId,
		lastServer = game.JobId,
		realTimeUpdate = true
	}

	task.spawn(function()
		if actualSummits > 0 then
			local success1 = safeSetAsync(globalSummitStore, player.UserId, -actualSummits)
			if success1 then
				lastSavedSummits[player.UserId] = actualSummits
			end
		end

		-- Simpan metadata player untuk leaderboard
		safeSetAsync(persistentDataStore, player.UserId, playerData)
		-- playerDataStore dihapus - data summit sudah di ProfileStore
	end)
end

local function updateDualLeaderboardData()
	local success, pages = pcall(function()
		return globalSummitStore:GetSortedAsync(true, LEADERBOARD_SIZE)
	end)

	if not success then
		warn("[Leaderboard] Failed to fetch data:", pages)
		return
	end

	local topPlayers = {}
	local currentPage = pages:GetCurrentPage()

	for _, entry in pairs(currentPage) do
		local userId = tonumber(entry.key)
		if userId and not isExcludedStaff(userId) then
			local summits = math.abs(entry.value)

			local persistentData = safeGetAsync(persistentDataStore, userId)

			if persistentData then
				local timeSinceUpdate = tick() - (persistentData.lastSeen or 0)

				if timeSinceUpdate > RESET_IGNORE_WINDOW then
					table.insert(topPlayers, {
						name = persistentData.name or "Unknown",
						summits = summits,
						userId = userId,
						lastSeen = persistentData.lastSeen,
						role = getPlayerRole(userId)
					})
				end
			end
		end

		if #topPlayers >= LEADERBOARD_SIZE then
			break
		end
	end

	for _, player in pairs(Players:GetPlayers()) do
		local stats = player:FindFirstChild("leaderstats")
		local summits = stats and stats:FindFirstChild("Summits")
		if summits then
			local actualSummits = summits.Value

			local found = false
			for i, data in pairs(topPlayers) do
				if data.userId == player.UserId then
					topPlayers[i].summits = actualSummits
					topPlayers[i].lastSeen = tick()
					found = true
					break
				end
			end

			if not found and actualSummits > 0 and not isExcludedStaff(player.UserId) then
				table.insert(topPlayers, {
					name = player.Name,
					summits = actualSummits,
					userId = player.UserId,
					lastSeen = tick(),
					role = getPlayerRole(player.UserId)
				})
			end

			smartSaveToGlobalStore(player, actualSummits)
		end
	end

	table.sort(topPlayers, function(a, b)
		return a.summits > b.summits
	end)

	if #topPlayers > LEADERBOARD_SIZE then
		for i = #topPlayers, LEADERBOARD_SIZE + 1, -1 do
			table.remove(topPlayers, i)
		end
	end

	globalLeaderboardData = topPlayers
end

local function stopAllAnimations()
	for _, isActive in pairs(activeAnimations) do
		if isActive and isActive.Value ~= nil then
			isActive.Value = false
		end
	end
	activeAnimations = {}
end

local function disconnectAllConnections()
	for _, connection in pairs(activeConnections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end
	activeConnections = {}
end

local function createDualLocationSurface(part, locationName)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "GlobalLeaderboard_" .. locationName
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.AlwaysOnTop = false
	surfaceGui.LightInfluence = 0
	surfaceGui.CanvasSize = Vector2.new(part.Size.X * UI_PIXELS_PER_STUD, part.Size.Y * UI_PIXELS_PER_STUD)
	surfaceGui.Parent = part

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = surfaceGui

	local mainGradient = Instance.new("UIGradient")
	mainGradient.Color = GRADIENT_MAIN_FRAME
	mainGradient.Rotation = 45
	mainGradient.Parent = mainFrame

	local isActive = Instance.new("BoolValue")
	isActive.Value = true
	table.insert(activeAnimations, isActive)

	task.spawn(function()
		while isActive.Value and mainGradient and mainGradient.Parent do
			local tween = TweenService:Create(mainGradient,
				TweenInfo.new(ANIM_GRADIENT_ROTATION_DURATION, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
				{Rotation = mainGradient.Rotation + 360}
			)
			tween:Play()
			task.wait(ANIM_GRADIENT_ROTATION_DURATION)
		end
	end)

	local headerFrame = Instance.new("Frame")
	headerFrame.Size = UDim2.new(1, 0, 0.12, 0)
	headerFrame.Position = UDim2.new(0, 0, 0, 0)
	headerFrame.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = mainFrame

	local headerGradient = Instance.new("UIGradient")
	headerGradient.Color = GRADIENT_PURPLE_HEADER
	headerGradient.Rotation = 0
	headerGradient.Parent = headerFrame

	local isActive2 = Instance.new("BoolValue")
	isActive2.Value = true
	table.insert(activeAnimations, isActive2)

	task.spawn(function()
		while isActive2.Value and headerGradient and headerGradient.Parent do
			local tween = TweenService:Create(headerGradient,
				TweenInfo.new(ANIM_GRADIENT_ROTATION_DURATION, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
				{Rotation = headerGradient.Rotation + 360}
			)
			tween:Play()
			task.wait(ANIM_GRADIENT_ROTATION_DURATION)
		end
	end)

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 20)
	headerCorner.Parent = headerFrame

	local headerStroke = Instance.new("UIStroke")
	headerStroke.Color = Color3.fromRGB(255, 255, 255)
	headerStroke.Thickness = 3
	headerStroke.Transparency = 0.7
	headerStroke.Parent = headerFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🏔️ GLOBAL LEADERBOARD - " .. string.upper(locationName)
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextStrokeTransparency = 0
	titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	titleLabel.Parent = headerFrame

	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Size = UDim2.new(1, 0, 0.88, 0)
	scrollingFrame.Position = UDim2.new(0, 0, 0.12, 0)
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.ScrollBarThickness = 8
	scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
	scrollingFrame.BorderSizePixel = 0
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, (UI_ENTRY_HEIGHT + UI_LIST_PADDING) * LEADERBOARD_SIZE + UI_CANVAS_EXTRA_SPACE)
	scrollingFrame.Parent = mainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, UI_LIST_PADDING)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollingFrame

	local topPadding = Instance.new("UIPadding")
	topPadding.PaddingTop = UDim.new(0, UI_TOP_PADDING)
	topPadding.Parent = scrollingFrame

	return surfaceGui, scrollingFrame
end

local function createDualPlayerEntry(rank, playerData, parent)
	local entryFrame = Instance.new("Frame")
	entryFrame.Name = "Entry_" .. rank
	entryFrame.Size = UDim2.new(UI_ENTRY_WIDTH_SCALE, 0, 0, UI_ENTRY_HEIGHT)
	entryFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	entryFrame.BorderSizePixel = 0
	entryFrame.LayoutOrder = rank

	local gradient = Instance.new("UIGradient")
	if rank == 1 then
		gradient.Color = GRADIENT_RANK1
	elseif rank == 2 then
		gradient.Color = GRADIENT_RANK2
	elseif rank == 3 then
		gradient.Color = GRADIENT_RANK3
	elseif rank <= 10 then
		gradient.Color = GRADIENT_RANK_TOP10
	else
		gradient.Color = GRADIENT_RANK_NORMAL
	end
	gradient.Rotation = 90
	gradient.Parent = entryFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, rank <= 3 and UI_CORNER_RADIUS_TOP3 or UI_CORNER_RADIUS_NORMAL)
	corner.Parent = entryFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = rank <= 3 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(100, 100, 120)
	stroke.Thickness = rank <= 3 and UI_BORDER_THICKNESS_TOP3 or UI_BORDER_THICKNESS_NORMAL
	stroke.Transparency = rank <= 3 and 0.3 or 0.6
	stroke.Parent = entryFrame

	if rank <= 3 then
		local glowFrame = Instance.new("Frame")
		glowFrame.Name = "GlowEffect"
		glowFrame.Size = UDim2.new(1, 20, 1, 20)
		glowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		glowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		glowFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		glowFrame.BackgroundTransparency = 0.8
		glowFrame.BorderSizePixel = 0
		glowFrame.ZIndex = 0
		glowFrame.Parent = entryFrame

		local glowCorner = Instance.new("UICorner")
		glowCorner.CornerRadius = UDim.new(0, UI_CORNER_RADIUS_TOP3 + 5)
		glowCorner.Parent = glowFrame

		local glowGradient = Instance.new("UIGradient")
		glowGradient.Color = GRADIENT_PURPLE_GLOW
		glowGradient.Rotation = 0
		glowGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 0.2),
			NumberSequenceKeypoint.new(1, 0.5)
		})
		glowGradient.Parent = glowFrame

		local isActive = Instance.new("BoolValue")
		isActive.Value = true
		table.insert(activeAnimations, isActive)

		task.spawn(function()
			while isActive.Value and glowGradient and glowGradient.Parent do
				local tween = TweenService:Create(glowGradient,
					TweenInfo.new(ANIM_GLOW_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{Rotation = 360}
				)
				tween:Play()
				task.wait(ANIM_GLOW_DURATION)
			end
		end)
	end

	local rankContainer = Instance.new("Frame")
	rankContainer.Size = UDim2.new(0.18, 0, 1, 0)
	rankContainer.Position = UDim2.new(0, 0, 0, 0)
	rankContainer.BackgroundTransparency = 1
	rankContainer.Parent = entryFrame

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(1, 0, 0.7, 0)
	rankLabel.Position = UDim2.new(0, 0, 0.15, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Text = "#" .. rank
	rankLabel.TextColor3 = Color3.new(1, 1, 1)
	rankLabel.TextScaled = true
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.TextStrokeTransparency = 0
	rankLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	rankLabel.Parent = rankContainer

	local nameContainer = Instance.new("Frame")
	nameContainer.Size = UDim2.new(0.5, 0, 1, 0)
	nameContainer.Position = UDim2.new(0.18, 0, 0, 0)
	nameContainer.BackgroundTransparency = 1
	nameContainer.Parent = entryFrame

	local roleEmoji = ""
	if playerData.role then
		roleEmoji = ROLE_EMOJI[playerData.role] or ""
	end

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.Position = UDim2.new(0, 0, 0.2, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = roleEmoji .. " " .. playerData.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.Parent = nameContainer

	local summitContainer = Instance.new("Frame")
	summitContainer.Size = UDim2.new(0.32, 0, 1, 0)
	summitContainer.Position = UDim2.new(0.68, 0, 0, 0)
	summitContainer.BackgroundTransparency = 1
	summitContainer.Parent = entryFrame

	local summitText = tostring(playerData.summits)
	if playerData.summits >= 1000000 then
		summitText = string.format("%.1fM", playerData.summits / 1000000)
	elseif playerData.summits >= 1000 then
		summitText = string.format("%.1fK", playerData.summits / 1000)
	end

	local summitLabel = Instance.new("TextLabel")
	summitLabel.Size = UDim2.new(1, 0, 0.6, 0)
	summitLabel.Position = UDim2.new(0, 0, 0.1, 0)
	summitLabel.BackgroundTransparency = 1
	summitLabel.Text = summitText
	summitLabel.TextColor3 = Color3.new(1, 1, 1)
	summitLabel.TextScaled = true
	summitLabel.Font = Enum.Font.GothamBold
	summitLabel.TextStrokeTransparency = 0
	summitLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	summitLabel.Parent = summitContainer

	local summitSubLabel = Instance.new("TextLabel")
	summitSubLabel.Size = UDim2.new(1, 0, 0.3, 0)
	summitSubLabel.Position = UDim2.new(0, 0, 0.7, 0)
	summitSubLabel.BackgroundTransparency = 1
	summitSubLabel.Text = "SUMMITS"
	summitSubLabel.TextColor3 = Color3.new(1, 1, 1)
	summitSubLabel.TextScaled = true
	summitSubLabel.Font = Enum.Font.Gotham
	summitSubLabel.TextTransparency = 0.2
	summitSubLabel.Parent = summitContainer

	entryFrame.Parent = parent

	entryFrame.Position = UDim2.new(-1.5, 0, 0, 0)
	entryFrame.Size = UDim2.new(0, 0, 0, UI_ENTRY_HEIGHT)

	local slideIn = TweenService:Create(entryFrame,
		TweenInfo.new(ANIM_SLIDE_DURATION, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, rank * 0.08),
		{Position = UDim2.new(0, 0, 0, 0)}
	)

	local sizeIn = TweenService:Create(entryFrame,
		TweenInfo.new(ANIM_SIZE_DURATION, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false, rank * 0.08 + 0.2),
		{Size = UDim2.new(UI_ENTRY_WIDTH_SCALE, 0, 0, UI_ENTRY_HEIGHT)}
	)

	slideIn:Play()
	sizeIn:Play()
end

local function updateSingleDisplay(surfaceGui, listContainer, locationName)
	if not (surfaceGui and listContainer) then return end

	for _, child in pairs(listContainer:GetChildren()) do
		if child:IsA("Frame") and string.match(child.Name, "Entry_") then
			child:Destroy()
		end
	end

	if #globalLeaderboardData > 0 then
		for rank, playerData in pairs(globalLeaderboardData) do
			createDualPlayerEntry(rank, playerData, listContainer)

			-- BARU: Update avatar untuk rank 1 di Summit
			if rank == 1 and locationName == "SUMMIT" and summitAvatarModule then
				task.spawn(function()
					summitAvatarModule.SetRigHumanoidDescription(playerData.userId > 0 and playerData.userId or 1)
				end)
			end
		end
	end
end

local function updateDualDisplay()
	if isUpdatingDisplay then
		return
	end
	isUpdatingDisplay = true

	task.spawn(function()
		stopAllAnimations()
		updateSingleDisplay(basecampSurfaceGui, basecampListContainer, "BASECAMP")
		updateSingleDisplay(summitSurfaceGui, summitListContainer, "SUMMIT")
		isUpdatingDisplay = false
	end)
end

local function startDualUpdates()
	task.spawn(function()
		while true do
			updateDualLeaderboardData()
			task.wait(2)
			updateDualDisplay()
			task.wait(UPDATE_INTERVAL)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(120)
			for _, player in pairs(Players:GetPlayers()) do
				local stats = player:FindFirstChild("leaderstats")
				local summits = stats and stats:FindFirstChild("Summits")
				local actualSummits = summits and summits.Value or 0
				smartSaveToGlobalStore(player, actualSummits)
			end
		end
	end)
end

local function initializeDualGlobalLeaderboard()
	-- BASECAMP: cari langsung Part
	local basecampPart = Workspace:FindFirstChild(BASECAMP_BOARD_NAME, true)

	if not basecampPart then
		basecampPart = Instance.new("Part")
		basecampPart.Name = BASECAMP_BOARD_NAME
		basecampPart.Size = Vector3.new(25, 30, 2)
		basecampPart.Position = basecampPosition
		basecampPart.Anchored = true
		basecampPart.Material = Enum.Material.ForceField
		basecampPart.BrickColor = BrickColor.new("Really black")
		basecampPart.Parent = Workspace

		local pointLight = Instance.new("PointLight")
		pointLight.Color = Color3.fromRGB(138, 43, 226)
		pointLight.Brightness = 5
		pointLight.Range = 30
		pointLight.Parent = basecampPart

		local isActive = Instance.new("BoolValue")
		isActive.Value = true
		table.insert(activeAnimations, isActive)

		task.spawn(function()
			while isActive.Value and pointLight and pointLight.Parent do
				local colorTween = TweenService:Create(pointLight,
					TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{Color = Color3.fromRGB(255, 0, 255)}
				)
				local colorTween2 = TweenService:Create(pointLight,
					TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{Color = Color3.fromRGB(138, 43, 226)}
				)
				colorTween:Play()
				colorTween.Completed:Wait()
				colorTween2:Play()
				colorTween2.Completed:Wait()
			end
		end)
	else
		basecampPosition = basecampPart.Position
	end

	-- SUMMIT: cari Model dulu, lalu Part di dalamnya
	local summitModel = Workspace:FindFirstChild(SUMMIT_MODEL_NAME)
	local summitPart = nil

	if summitModel and summitModel:IsA("Model") then
		summitPart = summitModel:FindFirstChild(SUMMIT_BOARD_NAME)

		-- BARU: Load avatar module
		local avatarModel = summitModel:FindFirstChild(SUMMIT_AVATAR_MODEL_NAME)
		if avatarModel then
			local avatarScript = avatarModel:FindFirstChild("PlayAnimationInRig")
			if avatarScript and avatarScript:IsA("ModuleScript") then
				local success, module = pcall(function()
					return require(avatarScript)
				end)
				if success then
					summitAvatarModule = module
					--print("✅ Summit Avatar Module loaded successfully!")
				else
					warn("❌ Failed to load Summit Avatar Module:", module)
				end
			else
				warn("⚠️ PlayAnimationInRig script not found in SummitFirstPlaceAvatar")
			end
		else
			warn("⚠️ SummitFirstPlaceAvatar model not found")
		end
	end

	if not summitPart then
		warn("[Leaderboard] SummitLeaderboardPart tidak ditemukan di dalam SummitLeaderboardModel!")
		if not summitModel then
			summitModel = Instance.new("Model")
			summitModel.Name = SUMMIT_MODEL_NAME
			summitModel.Parent = Workspace
		end

		summitPart = Instance.new("Part")
		summitPart.Name = SUMMIT_BOARD_NAME
		summitPart.Size = Vector3.new(25, 30, 2)
		summitPart.Position = summitPosition
		summitPart.Anchored = true
		summitPart.Material = Enum.Material.ForceField
		summitPart.BrickColor = BrickColor.new("Really black")
		summitPart.Parent = summitModel

		local pointLight = Instance.new("PointLight")
		pointLight.Color = Color3.fromRGB(138, 43, 226)
		pointLight.Brightness = 5
		pointLight.Range = 30
		pointLight.Parent = summitPart

		local isActive = Instance.new("BoolValue")
		isActive.Value = true
		table.insert(activeAnimations, isActive)

		task.spawn(function()
			while isActive.Value and pointLight and pointLight.Parent do
				local colorTween = TweenService:Create(pointLight,
					TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{Color = Color3.fromRGB(255, 0, 255)}
				)
				local colorTween2 = TweenService:Create(pointLight,
					TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{Color = Color3.fromRGB(138, 43, 226)}
				)
				colorTween:Play()
				colorTween.Completed:Wait()
				colorTween2:Play()
				colorTween2.Completed:Wait()
			end
		end)
	else
		summitPosition = summitPart.Position
	end

	basecampSurfaceGui, basecampListContainer = createDualLocationSurface(basecampPart, "Basecamp")
	summitSurfaceGui, summitListContainer = createDualLocationSurface(summitPart, "Summit")

	updateDualLeaderboardData()
	task.wait(2)
	updateDualDisplay()

	startDualUpdates()

	--print("🎉 DUAL GLOBAL Leaderboard initialized with Avatar Support!")
end

game:BindToClose(function()
	stopAllAnimations()
	disconnectAllConnections()

	for _, player in pairs(Players:GetPlayers()) do
		local stats = player:FindFirstChild("leaderstats")
		local summits = stats and stats:FindFirstChild("Summits")
		if summits then
			smartSaveToGlobalStore(player, summits.Value)
		end
	end

	task.wait(3)
end)

task.wait(3)
initializeDualGlobalLeaderboard()