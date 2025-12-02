-- ============================================================================
-- MUSIC PLAYER SYSTEM (Enhanced with TopbarPlus)
-- ============================================================================
-- Music player with play/pause, skip, volume, and mute controls
-- Plays songs from ReplicatedStorage/Music folder
-- Toggle UI via TopbarPlus icon (top right corner)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load TopbarPlus Icon
local Icon
local IconModule = ReplicatedStorage:WaitForChild("Icon", 10)
if IconModule then
	Icon = require(IconModule)
else
	warn("[MusicPlayer] TopbarPlus not found")
	return
end

-- ============================================================================
-- CENTRALIZED CONFIGURATION
-- ============================================================================
local CONFIG = {
	-- Topbar Icon
	TopbarIcon = {
		ImageId = "rbxassetid://74116486976092", -- rbxassetid://YOUR_MUSIC_ICON
		Label = "Music",
	},

	-- UI Text
	UI = {
		HeaderTitle = "Mt.TualanV2 Music Player",
		VolumeLabel = "Volume", -- Will show as "Volume: XX%"
		ShowOnStart = true, -- Auto-play on start
	},

	-- Button Icons (ImageIds)
	Icons = {
		-- Playback control icons
		Playing = "rbxassetid://128839287823111", -- rbxassetid://YOUR_PLAYING_ICON (▶️)
		Paused = "rbxassetid://119189773109344", -- rbxassetid://YOUR_PAUSED_ICON (⏸️)
		Stop = "rbxassetid://119189773109344", -- rbxassetid://YOUR_STOP_ICON (⏹️)
		Next = "rbxassetid://134359341234917", -- rbxassetid://YOUR_NEXT_ICON (⏭️)
		Previous = "rbxassetid://91879037431829", -- rbxassetid://YOUR_PREVIOUS_ICON (⏮️)

		-- Volume control icons
		Muted = "rbxassetid://95429312069133", -- rbxassetid://YOUR_MUTED_ICON (🔇)
		Unmuted = "rbxassetid://115888602277072", -- rbxassetid://YOUR_UNMUTED_ICON (🔊)

		-- UI control icons
		Close = "rbxassetid://98778427242117", -- rbxassetid://YOUR_CLOSE_ICON (✕)
	},

	-- Audio Settings
	Audio = {
		DefaultVolume = 0.1, -- 2% default volume
		MinVolume = 0,
		MaxVolume = 1,
		AutoPlayCategory = "Nyantai", -- Category to auto-play on start (set to "" to disable or play first song from any category)
	},
}

-- Shortcuts
local DEFAULT_VOLUME = CONFIG.Audio.DefaultVolume
local MIN_VOLUME = CONFIG.Audio.MinVolume
local MAX_VOLUME = CONFIG.Audio.MaxVolume

-- Music Player State
local MusicPlayer = {
	CurrentIndex = 1,
	Songs = {},
	Volume = DEFAULT_VOLUME,
	IsMuted = false,
	IsPlaying = false,
	Sound = nil,
}

-- ============================================================================
-- LOAD SONGS FROM MUSIC/CATEGORY FOLDER (Dynamic Categories)
-- ============================================================================
local function loadSongs()
	local musicFolder = ReplicatedStorage:FindFirstChild("Music")

	if not musicFolder then
		warn("[MusicPlayer] Music folder not found in ReplicatedStorage")
		return false
	end

	local categoryFolder = musicFolder:FindFirstChild("Category")
	if not categoryFolder then
		warn("[MusicPlayer] Category folder not found in Music folder")
		return false
	end

	-- Load songs from all category folders
	for _, folder in ipairs(categoryFolder:GetChildren()) do
		if folder:IsA("Folder") then
			for _, sound in ipairs(folder:GetChildren()) do
				if sound:IsA("Sound") then
					table.insert(MusicPlayer.Songs, { sound = sound, category = folder.Name })
				end
			end
		end
	end

	if #MusicPlayer.Songs == 0 then
		warn("[MusicPlayer] No songs found in Category folders")
		return false
	end

	print("[MusicPlayer] Loaded " .. #MusicPlayer.Songs .. " songs from categories")
	return true
end

-- Natural sort function (for alphanumeric sorting)
local function naturalSortCompare(a_name, b_name)
	local textA, numA = a_name:match("^(.-)(%d*)$")
	local textB, numB = b_name:match("^(.-)(%d*)$")
	local nA = (numA ~= "" and tonumber(numA)) or 0
	local nB = (numB ~= "" and tonumber(numB)) or 0
	local tA = textA:lower()
	local tB = textB:lower()

	if tA ~= tB then
		return tA < tB
	end
	return nA < nB
end

-- ============================================================================
-- FORWARD DECLARATIONS (Must be before createMusicPlayerUI)
-- ============================================================================
local playSong -- Forward declaration
local pauseSong
local resumeSong
local playNext
local updateSongIndicators

-- ============================================================================
-- CREATE MUSIC PLAYER UI (Settings-style Frame)
-- ============================================================================
local musicPlayerUI = nil
local volumeSlider = nil
local volumeBar = nil
local volumeLabel = nil
local songListContainer = nil -- Reference to ScrollingFrame for updateSongIndicators
local musicIcon = nil -- TopbarPlus icon
local isFrameOpen = false

-- Check if mobile device
local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- Check device type with viewport size detection
local function getDeviceType()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local width = viewportSize.X
	local height = viewportSize.Y

	-- Small landscape phone (height < 450 or width < 900)
	if height < 450 or width < 900 then
		return "SmallPhone"
	-- Regular mobile/tablet (touch enabled)
	elseif isMobile() then
		return "Mobile"
	-- Desktop/laptop
	else
		return "Desktop"
	end
end

local function createMusicPlayerUI()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MusicPlayerGUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	screenGui.IgnoreGuiInset = true
	screenGui.Enabled = false -- Hidden by default
	screenGui.Parent = playerGui

	-- Main Frame (Responsive sizing based on device)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	-- Size based on device type
	local deviceType = getDeviceType()
	if deviceType == "SmallPhone" then
		-- Small landscape phones (iPhone, Samsung Galaxy, etc)
		mainFrame.Size = UDim2.new(0.92, 0, 0.95, 0) -- Almost fullscreen to fit all elements
	elseif deviceType == "Mobile" then
		-- Tablets and larger mobiles
		mainFrame.Size = UDim2.new(0.90, 0, 0.85, 0)
	else
		-- Desktop/laptop
		mainFrame.Size = UDim2.new(0, 700, 0, 550)
	end

	mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = mainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = Color3.fromRGB(60, 60, 60)
	mainStroke.Thickness = 2
	mainStroke.Parent = mainFrame

	-- Header (smaller on small phones)
	local header = Instance.new("Frame")
	header.Name = "Header"
	local headerHeight = deviceType == "SmallPhone" and 40 or 50
	header.Size = UDim2.new(1, 0, 0, headerHeight)
	header.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	-- Header Title
	local headerTitle = Instance.new("TextLabel")
	headerTitle.Size = UDim2.new(1, -100, 1, 0)
	headerTitle.Position = UDim2.new(0, 15, 0, 0)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = CONFIG.UI.HeaderTitle
	headerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	headerTitle.Font = Enum.Font.GothamBold
	headerTitle.TextSize = 16
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.Parent = header

	-- Close Button
	local closeButton = Instance.new("ImageButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -50, 0.5, -20)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Image = CONFIG.Icons.Close
	closeButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.ScaleType = Enum.ScaleType.Fit
	closeButton.AutoButtonColor = false
	closeButton.Parent = header

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	-- Close button hover effects
	closeButton.MouseEnter:Connect(function()
		closeButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
	end)

	closeButton.MouseLeave:Connect(function()
		closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	end)

	-- Search Bar (smaller on small phones)
	local searchFrame = Instance.new("Frame")
	searchFrame.Name = "SearchBar"
	local searchHeight = deviceType == "SmallPhone" and 28 or (isMobile() and 35 or 38)
	local searchPosY = deviceType == "SmallPhone" and 42 or (isMobile() and 50 or 55)
	searchFrame.Size = UDim2.new(1, -30, 0, searchHeight)
	searchFrame.Position = UDim2.new(0, 15, 0, searchPosY)
	searchFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	searchFrame.BorderSizePixel = 0
	searchFrame.Parent = mainFrame

	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 8)
	searchCorner.Parent = searchFrame

	local searchStroke = Instance.new("UIStroke")
	searchStroke.Color = Color3.fromRGB(60, 60, 60)
	searchStroke.Thickness = 1
	searchStroke.Parent = searchFrame

	local searchBox = Instance.new("TextBox")
	searchBox.Name = "SearchBox"
	searchBox.Size = UDim2.new(1, -15, 1, 0)
	searchBox.Position = UDim2.new(0, 10, 0, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.Text = ""
	searchBox.PlaceholderText = "🔍 Search music..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	searchBox.TextSize = deviceType == "SmallPhone" and 10 or (isMobile() and 12 or 14)
	searchBox.Font = Enum.Font.Gotham
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchFrame

	-- IMPORTANT: Declare selectedCategory BEFORE creating buttons!
	local selectedCategory = "" -- Empty by default, only load when user clicks category

	-- Category Buttons (smaller on small phones)
	local categoryFrame = Instance.new("Frame")
	categoryFrame.Name = "CategoryButtons"
	local categoryHeight = deviceType == "SmallPhone" and 26 or (isMobile() and 32 or 35)
	local categoryPosY = deviceType == "SmallPhone" and 72 or (isMobile() and 92 or 100)
	categoryFrame.Size = UDim2.new(1, -30, 0, categoryHeight)
	categoryFrame.Position = UDim2.new(0, 15, 0, categoryPosY)
	categoryFrame.BackgroundTransparency = 1
	categoryFrame.Parent = mainFrame

	local categoryLayout = Instance.new("UIListLayout")
	categoryLayout.FillDirection = Enum.FillDirection.Horizontal
	categoryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	categoryLayout.Padding = UDim.new(0, 8)
	categoryLayout.Parent = categoryFrame

	-- Dynamic category loading (NO "All" category)
	local categories = {}
	local musicFolder = ReplicatedStorage:FindFirstChild("Music")
	if musicFolder then
		local categoryFolder = musicFolder:FindFirstChild("Category")
		if categoryFolder then
			for _, folder in ipairs(categoryFolder:GetChildren()) do
				if folder:IsA("Folder") then
					table.insert(categories, folder.Name)
				end
			end
		end
	end

	-- Sort categories alphabetically
	table.sort(categories, function(a, b)
		return a:lower() < b:lower()
	end)

	local categoryButtons = {}

	for _, categoryName in ipairs(categories) do
		local catButton = Instance.new("TextButton")
		local catButtonWidth = deviceType == "SmallPhone" and 60 or (isMobile() and 70 or 80)
		catButton.Size = UDim2.new(0, catButtonWidth, 1, 0)
		catButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		catButton.BackgroundTransparency = 0.5 -- All unselected by default
		catButton.BorderSizePixel = 0
		catButton.Text = categoryName:upper()
		catButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		local catTextSize = deviceType == "SmallPhone" and 8 or (isMobile() and 10 or 11)
		catButton.TextSize = catTextSize
		catButton.Font = Enum.Font.GothamBold
		catButton.Parent = categoryFrame

		local catCorner = Instance.new("UICorner")
		catCorner.CornerRadius = UDim.new(0, 6)
		catCorner.Parent = catButton

		local catStroke = Instance.new("UIStroke")
		catStroke.Color = Color3.fromRGB(0, 200, 100)
		catStroke.Thickness = 1 -- All unselected by default
		catStroke.Transparency = 0.7
		catStroke.Parent = catButton

		categoryButtons[categoryName] = { button = catButton, stroke = catStroke }

		catButton.MouseButton1Click:Connect(function()
			selectedCategory = categoryName -- Update local variable (closure)
			for name, data in pairs(categoryButtons) do
				if name == categoryName then
					data.button.BackgroundTransparency = 0.2
					data.stroke.Thickness = 2
					data.stroke.Transparency = 0.3
				else
					data.button.BackgroundTransparency = 0.5
					data.stroke.Thickness = 1
					data.stroke.Transparency = 0.7
				end
			end
			updateSongList()
		end)
	end

	-- Content Container (ScrollingFrame for song list)
	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	-- Adjust spacing based on device type
	local contentSpaceBottom = deviceType == "SmallPhone" and 230 or 330
	local contentPosY = deviceType == "SmallPhone" and 100 or (isMobile() and 132 or 142)
	content.Size = UDim2.new(1, -20, 1, -contentSpaceBottom) -- Leave space for all controls
	content.Position = UDim2.new(0, 10, 0, contentPosY) -- Below category buttons
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 8
	content.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 100)
	content.ScrollingDirection = Enum.ScrollingDirection.Y
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.Parent = mainFrame

	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingLeft = UDim.new(0, 5)
	contentPadding.PaddingRight = UDim.new(0, 5)
	contentPadding.Parent = content

	local contentList = Instance.new("UIListLayout")
	contentList.SortOrder = Enum.SortOrder.LayoutOrder
	contentList.Padding = UDim.new(0, 5)
	contentList.Parent = content

	-- Local reference for scroll frame (like EmoteController)
	local scrollFrame = content
	songListContainer = content -- Set module-level variable for updateSongIndicators()

	-- Now Playing Container (smaller on small phones)
	local nowPlayingContainer = Instance.new("Frame")
	nowPlayingContainer.Name = "NowPlaying"
	local nowPlayingHeight = deviceType == "SmallPhone" and 35 or 50
	local nowPlayingPosY = deviceType == "SmallPhone" and -185 or -250
	nowPlayingContainer.Size = UDim2.new(1, -20, 0, nowPlayingHeight)
	nowPlayingContainer.Position = UDim2.new(0, 10, 1, nowPlayingPosY)
	nowPlayingContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	nowPlayingContainer.BorderSizePixel = 0
	nowPlayingContainer.Parent = mainFrame

	local nowPlayingCorner = Instance.new("UICorner")
	nowPlayingCorner.CornerRadius = UDim.new(0, 8)
	nowPlayingCorner.Parent = nowPlayingContainer

	-- Now Playing Label
	local nowPlayingLabel = Instance.new("TextLabel")
	nowPlayingLabel.Name = "NowPlayingLabel"
	nowPlayingLabel.Size = UDim2.new(1, -20, 1, 0)
	nowPlayingLabel.Position = UDim2.new(0, 10, 0, 0)
	nowPlayingLabel.BackgroundTransparency = 1
	nowPlayingLabel.Text = "♪ No song playing"
	nowPlayingLabel.TextColor3 = Color3.fromRGB(0, 200, 100)
	nowPlayingLabel.Font = Enum.Font.GothamBold
	nowPlayingLabel.TextSize = deviceType == "SmallPhone" and 11 or (isMobile() and 13 or 14)
	nowPlayingLabel.TextXAlignment = Enum.TextXAlignment.Center
	nowPlayingLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nowPlayingLabel.Parent = nowPlayingContainer

	-- Progress Bar Container (smaller on small phones)
	local progressContainer = Instance.new("Frame")
	progressContainer.Name = "ProgressBar"
	local progressHeight = deviceType == "SmallPhone" and 30 or 40
	local progressPosY = deviceType == "SmallPhone" and -145 or -190
	progressContainer.Size = UDim2.new(1, -20, 0, progressHeight)
	progressContainer.Position = UDim2.new(0, 10, 1, progressPosY)
	progressContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	progressContainer.BorderSizePixel = 0
	progressContainer.Parent = mainFrame

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 8)
	progressCorner.Parent = progressContainer

	-- Time elapsed label
	local timeElapsedLabel = Instance.new("TextLabel")
	timeElapsedLabel.Name = "TimeElapsed"
	timeElapsedLabel.Size = UDim2.new(0, 40, 0, 15)
	timeElapsedLabel.Position = UDim2.new(0, 10, 0, 5)
	timeElapsedLabel.BackgroundTransparency = 1
	timeElapsedLabel.Text = "0:00"
	timeElapsedLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	timeElapsedLabel.Font = Enum.Font.Gotham
	timeElapsedLabel.TextSize = 11
	timeElapsedLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeElapsedLabel.Parent = progressContainer

	-- Time remaining label
	local timeRemainingLabel = Instance.new("TextLabel")
	timeRemainingLabel.Name = "TimeRemaining"
	timeRemainingLabel.Size = UDim2.new(0, 40, 0, 15)
	timeRemainingLabel.Position = UDim2.new(1, -50, 0, 5)
	timeRemainingLabel.BackgroundTransparency = 1
	timeRemainingLabel.Text = "0:00"
	timeRemainingLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	timeRemainingLabel.Font = Enum.Font.Gotham
	timeRemainingLabel.TextSize = 11
	timeRemainingLabel.TextXAlignment = Enum.TextXAlignment.Right
	timeRemainingLabel.Parent = progressContainer

	-- Progress bar track
	local progressTrack = Instance.new("Frame")
	progressTrack.Name = "ProgressTrack"
	progressTrack.Size = UDim2.new(1, -20, 0, 4)
	progressTrack.Position = UDim2.new(0, 10, 0, 25)
	progressTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	progressTrack.BorderSizePixel = 0
	progressTrack.Parent = progressContainer

	local progressTrackCorner = Instance.new("UICorner")
	progressTrackCorner.CornerRadius = UDim.new(0, 2)
	progressTrackCorner.Parent = progressTrack

	-- Progress bar fill
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressTrack

	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(0, 2)
	progressFillCorner.Parent = progressFill

	-- Playback Controls Container (3 buttons only, smaller on small phones)
	local playbackControlsContainer = Instance.new("Frame")
	playbackControlsContainer.Name = "PlaybackControls"
	local playbackHeight = deviceType == "SmallPhone" and 50 or 60
	local playbackPosY = deviceType == "SmallPhone" and -110 or -140
	playbackControlsContainer.Size = UDim2.new(1, -20, 0, playbackHeight)
	playbackControlsContainer.Position = UDim2.new(0, 10, 1, playbackPosY)
	playbackControlsContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	playbackControlsContainer.BorderSizePixel = 0
	playbackControlsContainer.Parent = mainFrame

	local playbackControlsCorner = Instance.new("UICorner")
	playbackControlsCorner.CornerRadius = UDim.new(0, 8)
	playbackControlsCorner.Parent = playbackControlsContainer

	-- Button size based on device type
	local buttonSize = deviceType == "SmallPhone" and 38 or (isMobile() and 45 or 50)

	-- Previous Button
	local previousButton = Instance.new("ImageButton")
	previousButton.Name = "PreviousButton"
	previousButton.Size = UDim2.new(0, buttonSize, 0, buttonSize)
	previousButton.Position = UDim2.new(0.5, -80, 0.5, -25)
	previousButton.AnchorPoint = Vector2.new(0.5, 0.5)
	previousButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	previousButton.BorderSizePixel = 0
	previousButton.Image = CONFIG.Icons.Previous
	previousButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	previousButton.ScaleType = Enum.ScaleType.Fit
	previousButton.AutoButtonColor = false
	previousButton.Parent = playbackControlsContainer

	local previousCorner = Instance.new("UICorner")
	previousCorner.CornerRadius = UDim.new(1, 0)
	previousCorner.Parent = previousButton

	-- Play/Pause Button (larger, center)
	local playPauseButton = Instance.new("ImageButton")
	playPauseButton.Name = "PlayPauseButton"
	playPauseButton.Size = UDim2.new(0, buttonSize + 10, 0, buttonSize + 10)
	playPauseButton.Position = UDim2.new(0.5, 0, 0.5, -30)
	playPauseButton.AnchorPoint = Vector2.new(0.5, 0.5)
	playPauseButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	playPauseButton.BorderSizePixel = 0
	playPauseButton.Image = CONFIG.Icons.Playing
	playPauseButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	playPauseButton.ScaleType = Enum.ScaleType.Fit
	playPauseButton.AutoButtonColor = false
	playPauseButton.Parent = playbackControlsContainer

	local playPauseCorner = Instance.new("UICorner")
	playPauseCorner.CornerRadius = UDim.new(1, 0)
	playPauseCorner.Parent = playPauseButton

	-- Next Button
	local nextButton = Instance.new("ImageButton")
	nextButton.Name = "NextButton"
	nextButton.Size = UDim2.new(0, buttonSize, 0, buttonSize)
	nextButton.Position = UDim2.new(0.5, 80, 0.5, -25)
	nextButton.AnchorPoint = Vector2.new(0.5, 0.5)
	nextButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	nextButton.BorderSizePixel = 0
	nextButton.Image = CONFIG.Icons.Next
	nextButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	nextButton.ScaleType = Enum.ScaleType.Fit
	nextButton.AutoButtonColor = false
	nextButton.Parent = playbackControlsContainer

	local nextCorner = Instance.new("UICorner")
	nextCorner.CornerRadius = UDim.new(1, 0)
	nextCorner.Parent = nextButton

	-- Volume Controls Container (bottom, smaller on small phones)
	local volumeControlsContainer = Instance.new("Frame")
	volumeControlsContainer.Name = "VolumeControls"
	local volumeHeight = deviceType == "SmallPhone" and 40 or 50
	local volumePosY = deviceType == "SmallPhone" and -55 or -70
	volumeControlsContainer.Size = UDim2.new(1, -20, 0, volumeHeight)
	volumeControlsContainer.Position = UDim2.new(0, 10, 1, volumePosY)
	volumeControlsContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	volumeControlsContainer.BorderSizePixel = 0
	volumeControlsContainer.Parent = mainFrame

	local volumeControlsCorner = Instance.new("UICorner")
	volumeControlsCorner.CornerRadius = UDim.new(0, 8)
	volumeControlsCorner.Parent = volumeControlsContainer

	-- Mute Button
	local muteButton = Instance.new("ImageButton")
	muteButton.Name = "MuteButton"
	muteButton.Size = UDim2.new(0, 30, 0, 30)
	muteButton.Position = UDim2.new(0, 10, 0, 10)
	muteButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	muteButton.BorderSizePixel = 0
	muteButton.Image = CONFIG.Icons.Unmuted
	muteButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	muteButton.ScaleType = Enum.ScaleType.Fit
	muteButton.AutoButtonColor = false
	muteButton.Parent = volumeControlsContainer

	local muteCorner = Instance.new("UICorner")
	muteCorner.CornerRadius = UDim.new(0, 6)
	muteCorner.Parent = muteButton

	-- Volume Label
	volumeLabel = Instance.new("TextLabel")
	volumeLabel.Size = UDim2.new(0, 80, 0, 20)
	volumeLabel.Position = UDim2.new(0, 50, 0, 15)
	volumeLabel.BackgroundTransparency = 1
	volumeLabel.Text = CONFIG.UI.VolumeLabel .. ": " .. math.floor(DEFAULT_VOLUME * 100) .. "%"
	volumeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	volumeLabel.Font = Enum.Font.GothamBold
	volumeLabel.TextSize = deviceType == "SmallPhone" and 9 or (isMobile() and 11 or 12)
	volumeLabel.TextXAlignment = Enum.TextXAlignment.Left
	volumeLabel.Parent = volumeControlsContainer

	-- Volume Slider Container
	local volumeSliderContainer = Instance.new("Frame")
	volumeSliderContainer.Size = UDim2.new(1, -150, 0, 20)
	volumeSliderContainer.Position = UDim2.new(0, 140, 0, 15)
	volumeSliderContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	volumeSliderContainer.BorderSizePixel = 0
	volumeSliderContainer.Parent = volumeControlsContainer

	local volumeSliderCorner = Instance.new("UICorner")
	volumeSliderCorner.CornerRadius = UDim.new(0, 10)
	volumeSliderCorner.Parent = volumeSliderContainer

	-- Volume Bar (Fill)
	volumeBar = Instance.new("Frame")
	volumeBar.Size = UDim2.new(DEFAULT_VOLUME, 0, 1, 0)
	volumeBar.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	volumeBar.BorderSizePixel = 0
	volumeBar.Parent = volumeSliderContainer

	local volumeBarCorner = Instance.new("UICorner")
	volumeBarCorner.CornerRadius = UDim.new(0, 10)
	volumeBarCorner.Parent = volumeBar

	-- Volume Slider (Invisible button)
	volumeSlider = Instance.new("TextButton")
	volumeSlider.Size = UDim2.new(1, 0, 1, 0)
	volumeSlider.BackgroundTransparency = 1
	volumeSlider.Text = ""
	volumeSlider.Parent = volumeSliderContainer

	musicPlayerUI = {
		ScreenGui = screenGui,
		MainFrame = mainFrame,
		Header = header,
		CloseButton = closeButton,
		Content = content,
		-- Search & Category
		SearchBox = searchBox,
		CategoryButtons = categoryButtons,
		-- Now Playing
		NowPlayingLabel = nowPlayingLabel,
		-- Progress Bar
		TimeElapsedLabel = timeElapsedLabel,
		TimeRemainingLabel = timeRemainingLabel,
		ProgressFill = progressFill,
		ProgressTrack = progressTrack,
		-- Playback controls (3 buttons only)
		PreviousButton = previousButton,
		PlayPauseButton = playPauseButton,
		NextButton = nextButton,
		-- Volume controls
		MuteButton = muteButton,
		VolumeSlider = volumeSlider,
		VolumeBar = volumeBar,
		VolumeLabel = volumeLabel,
	}

	-- ============================================================================
	-- UPDATE SONG LIST FUNCTION (Like EmoteController - inside createUI)
	-- ============================================================================
	function updateSongList()
		-- Clear existing items
		for _, child in pairs(scrollFrame:GetChildren()) do
			if child:IsA("Frame") and child.Name:match("^SongItem_") then
				child:Destroy()
			end
		end

		local searchText = searchBox.Text:lower()
		local songsToShow = {}

		-- Filter by category (only load when category is selected)
		if selectedCategory ~= "" then
			for _, songData in ipairs(MusicPlayer.Songs) do
				if songData.category == selectedCategory then
					table.insert(songsToShow, songData)
				end
			end
		end
		-- If selectedCategory is empty, songsToShow remains empty (no songs displayed)

		-- Sort songs alphabetically
		table.sort(songsToShow, function(a, b)
			return naturalSortCompare(a.sound.Name, b.sound.Name)
		end)

		-- Create song items (with search filter)
		local layoutOrder = 0
		for i, songData in ipairs(songsToShow) do
			local songName = songData.sound.Name:lower()

			-- Apply search filter
			if searchText == "" or songName:find(searchText, 1, true) then
				layoutOrder = layoutOrder + 1

				-- Create song item inline (smaller on small phones)
				local itemHeight = deviceType == "SmallPhone" and 38 or (isMobile() and 50 or 45)
				local textSize = deviceType == "SmallPhone" and 11 or (isMobile() and 13 or 14)

				local songItem = Instance.new("Frame")
				songItem.Name = "SongItem_" .. layoutOrder
				songItem.Size = UDim2.new(1, -10, 0, itemHeight)
				songItem.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
				songItem.BorderSizePixel = 0
				songItem.LayoutOrder = layoutOrder
				songItem.Parent = scrollFrame

				local itemCorner = Instance.new("UICorner")
				itemCorner.CornerRadius = UDim.new(0, 8)
				itemCorner.Parent = songItem

				-- Song button
				local songButton = Instance.new("TextButton")
				songButton.Size = UDim2.new(1, -10, 1, -10)
				songButton.Position = UDim2.new(0, 5, 0, 5)
				songButton.BackgroundTransparency = 1
				songButton.Text = ""
				songButton.Parent = songItem

				-- Song name label
				local songNameLabel = Instance.new("TextLabel")
				songNameLabel.Name = "SongNameLabel"
				songNameLabel.Size = UDim2.new(1, -140, 1, 0)
				songNameLabel.Position = UDim2.new(0, 10, 0, 0)
				songNameLabel.BackgroundTransparency = 1
				songNameLabel.Text = songData.sound.Name
				songNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				songNameLabel.Font = Enum.Font.GothamMedium
				songNameLabel.TextSize = textSize
				songNameLabel.TextXAlignment = Enum.TextXAlignment.Left
				songNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
				songNameLabel.Parent = songItem

				-- Category Tag (smaller on small phones)
				local categoryTag = Instance.new("TextLabel")
				categoryTag.Name = "CategoryTag"
				local tagHeight = deviceType == "SmallPhone" and 18 or (isMobile() and 22 or 24)
				local tagWidth = deviceType == "SmallPhone" and 55 or 70
				categoryTag.Size = UDim2.new(0, tagWidth, 0, tagHeight)
				local tagPosX = deviceType == "SmallPhone" and -88 or -108
				categoryTag.Position = UDim2.new(1, tagPosX, 0.5, -tagHeight / 2)
				categoryTag.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				categoryTag.BackgroundTransparency = 0.3
				categoryTag.BorderSizePixel = 0
				categoryTag.Text = songData.category:upper()
				categoryTag.TextColor3 = Color3.fromRGB(0, 200, 100)
				local tagTextSize = deviceType == "SmallPhone" and 7 or (isMobile() and 9 or 10)
				categoryTag.TextSize = tagTextSize
				categoryTag.Font = Enum.Font.GothamBold
				categoryTag.Parent = songItem

				local tagCorner = Instance.new("UICorner")
				tagCorner.CornerRadius = UDim.new(0, 5)
				tagCorner.Parent = categoryTag

				-- Play indicator
				local playIndicator = Instance.new("ImageLabel")
				playIndicator.Name = "PlayIndicator"
				playIndicator.Size = UDim2.new(0, 24, 0, 24)
				playIndicator.Position = UDim2.new(1, -32, 0.5, -12)
				playIndicator.BackgroundTransparency = 1
				playIndicator.Image = ""
				playIndicator.ImageColor3 = Color3.fromRGB(0, 200, 100)
				playIndicator.ScaleType = Enum.ScaleType.Fit
				playIndicator.Parent = songItem

				-- Hover effect
				if not isMobile() then
					songButton.MouseEnter:Connect(function()
						songItem.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
					end)

					songButton.MouseLeave:Connect(function()
						songItem.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
					end)
				end

				-- Click to play
				songButton.MouseButton1Click:Connect(function()
					-- Find actual index in MusicPlayer.Songs array
					for actualIndex, actualSongData in ipairs(MusicPlayer.Songs) do
						if actualSongData == songData then
							MusicPlayer.CurrentIndex = actualIndex
							playSong()
							break
						end
					end
				end)
			end
		end
	end

	-- NO initial populate - only load when user clicks a category

	-- Setup search functionality (filters within selected category)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		updateSongList()
	end)

	return musicPlayerUI
end

-- ============================================================================
-- SLIDE ANIMATION
-- ============================================================================
local function slideIn()
	if isFrameOpen then
		return
	end

	isFrameOpen = true
	musicPlayerUI.ScreenGui.Enabled = true

	-- Slide animation from right
	musicPlayerUI.MainFrame.Position = UDim2.new(1.5, 0, 0.5, 0) -- Start off-screen right

	local tween = TweenService:Create(
		musicPlayerUI.MainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0.5, 0) } -- Center
	)
	tween:Play()
end

local function slideOut()
	if not isFrameOpen then
		return
	end

	isFrameOpen = false

	-- Slide animation to right
	local tween = TweenService:Create(
		musicPlayerUI.MainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
		{ Position = UDim2.new(1.5, 0, 0.5, 0) } -- Off-screen right
	)

	tween:Play()
	tween.Completed:Connect(function()
		musicPlayerUI.ScreenGui.Enabled = false
	end)
end

-- ============================================================================
-- MUSIC PLAYBACK LOGIC
-- ============================================================================

-- Create sound instance
local function createSoundInstance()
	local sound = Instance.new("Sound")
	sound.Name = "MusicPlayerSound"
	sound.Parent = script
	sound.Volume = MusicPlayer.Volume
	MusicPlayer.Sound = sound
	return sound
end

-- Update song indicators in list
updateSongIndicators = function()
	if #MusicPlayer.Songs == 0 then
		return
	end

	local currentSongData = MusicPlayer.Songs[MusicPlayer.CurrentIndex]

	-- Update all visible song items in the filtered list
	for _, child in ipairs(songListContainer:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^SongItem_") then
			local playIndicator = child:FindFirstChild("PlayIndicator")
			if playIndicator then
				-- Get the song name from the SongNameLabel to match with current song
				local songNameLabel = child:FindFirstChild("SongNameLabel")
				if songNameLabel and songNameLabel.Text == currentSongData.sound.Name then
					if MusicPlayer.IsPlaying then
						playIndicator.Image = CONFIG.Icons.Playing
					else
						playIndicator.Image = CONFIG.Icons.Paused
					end
				else
					playIndicator.Image = ""
				end
			end
		end
	end
end

-- Play current song
playSong = function()
	if #MusicPlayer.Songs == 0 then
		return
	end

	local songData = MusicPlayer.Songs[MusicPlayer.CurrentIndex]
	local currentSound = songData.sound -- Extract Sound object from {sound, category}

	-- Stop current sound (set IsPlaying to false FIRST to prevent event loop)
	MusicPlayer.IsPlaying = false
	if MusicPlayer.Sound then
		MusicPlayer.Sound:Stop()
	end

	-- Set new sound properties
	MusicPlayer.Sound.SoundId = currentSound.SoundId
	MusicPlayer.Sound.Volume = MusicPlayer.IsMuted and 0 or MusicPlayer.Volume

	-- Play
	MusicPlayer.Sound:Play()
	MusicPlayer.IsPlaying = true

	-- Update UI
	updateSongIndicators()
	-- Update now playing
	musicPlayerUI.NowPlayingLabel.Text = "♪ " .. currentSound.Name

	print("[MusicPlayer] Playing: " .. currentSound.Name)
end

-- Pause current song
pauseSong = function()
	if MusicPlayer.Sound then
		MusicPlayer.Sound:Pause()
		MusicPlayer.IsPlaying = false
		updateSongIndicators()
		print("[MusicPlayer] Paused")
	end
end

-- Resume song
resumeSong = function()
	if MusicPlayer.Sound then
		MusicPlayer.Sound:Resume()
		MusicPlayer.IsPlaying = true
		updateSongIndicators()
		print("[MusicPlayer] Resumed")
	end
end

-- Play next song
playNext = function()
	MusicPlayer.CurrentIndex = MusicPlayer.CurrentIndex + 1

	if MusicPlayer.CurrentIndex > #MusicPlayer.Songs then
		MusicPlayer.CurrentIndex = 1 -- Loop back to first song
	end

	playSong()
end

-- Play previous song
local playPrevious = function()
	MusicPlayer.CurrentIndex = MusicPlayer.CurrentIndex - 1

	if MusicPlayer.CurrentIndex < 1 then
		MusicPlayer.CurrentIndex = #MusicPlayer.Songs -- Loop to last song
	end

	playSong()
end

-- Format time (seconds to MM:SS)
local function formatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", mins, secs)
end

-- Update progress bar
local function updateProgressBar()
	if not MusicPlayer.Sound or not MusicPlayer.IsPlaying then
		return
	end

	local timePosition = MusicPlayer.Sound.TimePosition
	local timeLength = MusicPlayer.Sound.TimeLength

	if timeLength > 0 then
		local progress = timePosition / timeLength
		musicPlayerUI.ProgressFill.Size = UDim2.new(progress, 0, 1, 0)
		musicPlayerUI.TimeElapsedLabel.Text = formatTime(timePosition)
		musicPlayerUI.TimeRemainingLabel.Text = formatTime(timeLength)
	end
end

-- Toggle play/pause
local togglePlayPause = function()
	if MusicPlayer.IsPlaying then
		pauseSong()
		-- Update button to show play icon
		musicPlayerUI.PlayPauseButton.Image = CONFIG.Icons.Playing
		musicPlayerUI.PlayPauseButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	else
		if MusicPlayer.Sound and MusicPlayer.Sound.TimePosition > 0 then
			resumeSong()
		else
			playSong()
		end
		-- Update button to show pause icon
		musicPlayerUI.PlayPauseButton.Image = CONFIG.Icons.Paused
		musicPlayerUI.PlayPauseButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
	end
end

-- Toggle mute
local toggleMute = function()
	MusicPlayer.IsMuted = not MusicPlayer.IsMuted

	if MusicPlayer.Sound then
		MusicPlayer.Sound.Volume = MusicPlayer.IsMuted and 0 or MusicPlayer.Volume
	end

	-- Update mute button icon
	if MusicPlayer.IsMuted then
		musicPlayerUI.MuteButton.Image = CONFIG.Icons.Muted
		musicPlayerUI.MuteButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	else
		musicPlayerUI.MuteButton.Image = CONFIG.Icons.Unmuted
		musicPlayerUI.MuteButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	end

	print("[MusicPlayer] Mute:", MusicPlayer.IsMuted)
end

-- Set volume
local function setVolume(volume)
	MusicPlayer.Volume = math.clamp(volume, MIN_VOLUME, MAX_VOLUME)

	if not MusicPlayer.IsMuted and MusicPlayer.Sound then
		MusicPlayer.Sound.Volume = MusicPlayer.Volume
	end

	-- Update volume bar and label
	volumeBar.Size = UDim2.new(MusicPlayer.Volume / MAX_VOLUME, 0, 1, 0)
	volumeLabel.Text = CONFIG.UI.VolumeLabel .. ": " .. math.floor(MusicPlayer.Volume * 100) .. "%"
end

-- ============================================================================
-- VOLUME SLIDER INTERACTION (Fixed: Only update on click, not hover)
-- ============================================================================
local function setupVolumeSlider()
	local isDragging = false

	local function updateVolumeFromClick(input)
		local relativeX = input.Position.X - volumeSlider.AbsolutePosition.X
		local percentage = math.clamp(relativeX / volumeSlider.AbsoluteSize.X, 0, 1)
		setVolume(percentage * MAX_VOLUME)
	end

	-- Handle initial click and drag start
	volumeSlider.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			isDragging = true
			updateVolumeFromClick(input)

			-- Track when dragging ends
			local connection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					isDragging = false
					connection:Disconnect()
				end
			end)
		end
	end)

	-- Only update volume during active dragging (not on hover)
	volumeSlider.InputChanged:Connect(function(input)
		if not isDragging then
			return
		end -- FIXED: Ignore hover without click

		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			updateVolumeFromClick(input)
		end
	end)
end

-- ============================================================================
-- TOPBAR ICON - OPEN FRAME (NO TOGGLE)
-- ============================================================================
local function createMusicIcon()
	musicIcon = Icon.new()
	musicIcon:setName("MusicPlayer")
	musicIcon:setOrder(100) -- High order = position on right side of topbar

	-- Set image and label from config
	if CONFIG.TopbarIcon.ImageId ~= "" then
		musicIcon:setImage(CONFIG.TopbarIcon.ImageId)
	end

	if CONFIG.TopbarIcon.Label ~= "" then
		musicIcon:setLabel(CONFIG.TopbarIcon.Label)
	end

	-- Open frame when clicked (not toggle)
	musicIcon.selected:Connect(function()
		slideIn()
		task.wait(0.1)
		musicIcon:deselect() -- Deselect immediately (button behavior, not toggle)
	end)

	return musicIcon
end

-- ============================================================================
-- SETUP EVENT HANDLERS
-- ============================================================================
local function setupEventHandlers()
	-- Close button
	musicPlayerUI.CloseButton.MouseButton1Click:Connect(slideOut)

	-- Playback control buttons (3 buttons only)
	musicPlayerUI.PreviousButton.MouseButton1Click:Connect(playPrevious)
	musicPlayerUI.PlayPauseButton.MouseButton1Click:Connect(togglePlayPause)
	musicPlayerUI.NextButton.MouseButton1Click:Connect(playNext)

	-- Volume control
	musicPlayerUI.MuteButton.MouseButton1Click:Connect(toggleMute)

	-- Song ended - auto play next song
	MusicPlayer.Sound.Ended:Connect(playNext)

	-- ✅ OPTIMIZED: Update progress bar setiap 0.5s instead of 60 FPS
	-- Reduces CPU usage by 96% (60 Hz → 2 Hz)
	task.spawn(function()
		while true do
			task.wait(0.5) -- Update 2x per second instead of 60x
			if MusicPlayer.Sound and MusicPlayer.IsPlaying then
				updateProgressBar()
			end
		end
	end)
end

-- ============================================================================
-- INITIALIZE MUSIC PLAYER
-- ============================================================================
local function initialize()
	-- Load songs from Music folder
	local songsLoaded = loadSongs()
	if not songsLoaded then
		return
	end

	-- Create UI (updateSongList is now called inside createMusicPlayerUI)
	createMusicPlayerUI()

	-- Create sound instance
	createSoundInstance()

	-- Setup volume slider
	setupVolumeSlider()

	-- Setup event handlers
	setupEventHandlers()

	-- Create TopbarPlus icon (right side of topbar)
	task.wait(0.5) -- Wait for TopbarPlus to be ready
	createMusicIcon()

	-- Auto-play first song from specified category if ShowOnStart is true
	if CONFIG.UI.ShowOnStart then
		task.wait(1)

		local autoPlayCategory = CONFIG.Audio.AutoPlayCategory

		if autoPlayCategory ~= "" then
			-- Find first song from specified category
			local songIndex = nil
			for i, songData in ipairs(MusicPlayer.Songs) do
				if songData.category == autoPlayCategory then
					songIndex = i
					break
				end
			end

			if songIndex then
				MusicPlayer.CurrentIndex = songIndex
				playSong()
				print("[MusicPlayer] Auto-playing from category:", autoPlayCategory)
			else
				warn("[MusicPlayer] No songs found in category '" .. autoPlayCategory .. "' for auto-play")
			end
		else
			-- If AutoPlayCategory is empty, play first song from any category
			if #MusicPlayer.Songs > 0 then
				MusicPlayer.CurrentIndex = 1
				playSong()
				print("[MusicPlayer] Auto-playing first song (no category filter)")
			end
		end
	end

	print("✅ [MusicPlayer] Music Player initialized with " .. #MusicPlayer.Songs .. " songs")
end

-- Start initialization
task.wait(2) -- Wait for game to load
initialize()
