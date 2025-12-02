--[[
    BoomBox Client Script - COMPACT VERSION
    Smaller UI for mobile/desktop
--]]

local Tool = script.Parent
local Remote = Tool:WaitForChild("BoomboxRemote")
local Player = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Variables
local mainGui = nil
local playlist = {}
local currentSongIndex = 1
local isPlaying = false
local isPaused = false
local isDragging = false
local dragStart = nil
local startPos = nil

-- Default playlist
local defaultPlaylist = {
	{id = "122665842844850", name = "cekini"},
	{id = "119254319180287", name = "DJ Sayang Culik aku dong"},
	{id = "139949361459626", name = "Reza Arap"},
	{id = "71770806375906", name = "TAK SOGOK"},
	{id = "113501115358940", name = "MOREN"},
	{id = "116101796636534", name = "REMIXER"},
	{id = "110720234629849", name = "MANIS"},
}

-- UI Colors
local COLORS = {
	primary = Color3.fromRGB(88, 101, 242),
	secondary = Color3.fromRGB(114, 137, 218),
	background = Color3.fromRGB(32, 34, 37),
	surface = Color3.fromRGB(47, 49, 54),
	text = Color3.fromRGB(255, 255, 255),
	textDim = Color3.fromRGB(185, 187, 190),
	success = Color3.fromRGB(67, 181, 129),
	danger = Color3.fromRGB(240, 71, 71),
}

function createMainGui()
	if Player.PlayerGui:FindFirstChild("BoomBoxGui") then
		Player.PlayerGui:FindFirstChild("BoomBoxGui"):Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BoomBoxGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Main Frame - LEBIH KECIL!
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 240, 0, 320)
	mainFrame.Position = UDim2.new(0.5, -120, 0.5, -160)
	mainFrame.BackgroundColor3 = COLORS.background
	mainFrame.BorderSizePixel = 0
	mainFrame.Active = true
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = mainFrame

	-- Header
	createHeader(mainFrame)

	-- Now Playing
	createNowPlaying(mainFrame)

	-- Controls
	createControls(mainFrame)

	-- Playlist
	createPlaylistSection(mainFrame)

	-- Add Song
	createAddSongSection(mainFrame)

	-- Setup dragging
	setupDragging(mainFrame)

	mainGui = screenGui
	screenGui.Parent = Player.PlayerGui

	playlist = defaultPlaylist
	updatePlaylistDisplay()
end

function setupDragging(frame)
	local header = frame:FindFirstChild("Header")
	if not header then return end

	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)

	header.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
			input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

function createHeader(parent)
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 36)
	header.BackgroundColor3 = COLORS.surface
	header.BorderSizePixel = 0
	header.Parent = parent

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 8)
	headerCorner.Parent = header

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 1, 0)
	title.Position = UDim2.new(0, 8, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🎵 BoomBox nrhdxbb"
	title.TextColor3 = COLORS.text
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	-- Close Button
	local closeBtn = createButton("X", UDim2.new(0, 28, 0, 28), UDim2.new(1, -32, 0.5, -14))
	closeBtn.BackgroundColor3 = COLORS.danger
	closeBtn.TextSize = 14
	closeBtn.Parent = header
	closeBtn.MouseButton1Click:Connect(function()
		if mainGui then
			mainGui:Destroy()
			mainGui = nil
		end
	end)
end

function createNowPlaying(parent)
	local frame = Instance.new("Frame")
	frame.Name = "NowPlaying"
	frame.Size = UDim2.new(1, -16, 0, 48)
	frame.Position = UDim2.new(0, 8, 0, 42)
	frame.BackgroundColor3 = COLORS.surface
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 32, 0, 32)
	icon.Position = UDim2.new(0, 8, 0.5, -16)
	icon.BackgroundTransparency = 1
	icon.Text = "🎵"
	icon.TextSize = 18
	icon.Parent = frame

	-- Song Name
	local songName = Instance.new("TextLabel")
	songName.Name = "SongName"
	songName.Size = UDim2.new(1, -48, 0, 20)
	songName.Position = UDim2.new(0, 44, 0, 8)
	songName.BackgroundTransparency = 1
	songName.Text = "No song playing"
	songName.TextColor3 = COLORS.text
	songName.TextSize = 12
	songName.Font = Enum.Font.GothamBold
	songName.TextXAlignment = Enum.TextXAlignment.Left
	songName.TextTruncate = Enum.TextTruncate.AtEnd
	songName.Parent = frame

	-- Status
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -48, 0, 14)
	status.Position = UDim2.new(0, 44, 0, 26)
	status.BackgroundTransparency = 1
	status.Text = "Ready"
	status.TextColor3 = COLORS.textDim
	status.TextSize = 10
	status.Font = Enum.Font.Gotham
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = frame
end

function createControls(parent)
	local frame = Instance.new("Frame")
	frame.Name = "Controls"
	frame.Size = UDim2.new(1, -16, 0, 44)
	frame.Position = UDim2.new(0, 8, 0, 96)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local buttonSize = UDim2.new(0, 42, 0, 42)
	local spacing = 6
	local totalWidth = (42 * 4) + (spacing * 3)
	local startX = (224 - totalWidth) / 2

	-- Previous Button
	local prevBtn = createButton("⏮", buttonSize, UDim2.new(0, startX, 0, 0))
	prevBtn.BackgroundColor3 = COLORS.secondary
	prevBtn.TextSize = 14
	prevBtn.Parent = frame
	prevBtn.MouseButton1Click:Connect(function()
		Remote:FireServer("Previous")
	end)

	-- Play/Pause Button
	local playBtn = createButton("▶", buttonSize, UDim2.new(0, startX + 48, 0, 0))
	playBtn.Name = "PlayButton"
	playBtn.BackgroundColor3 = COLORS.primary
	playBtn.TextSize = 14
	playBtn.Parent = frame
	playBtn.MouseButton1Click:Connect(function()
		if isPlaying and not isPaused then
			Remote:FireServer("Pause")
			playBtn.Text = "▶"
			isPaused = true
		elseif isPaused then
			Remote:FireServer("Resume")
			playBtn.Text = "⏸"
			isPaused = false
		else
			if #playlist > 0 then
				Remote:FireServer("PlayFromPlaylist", currentSongIndex)
				playBtn.Text = "⏸"
			end
		end
	end)

	-- Stop Button
	local stopBtn = createButton("⏹", buttonSize, UDim2.new(0, startX + 96, 0, 0))
	stopBtn.BackgroundColor3 = COLORS.danger
	stopBtn.TextSize = 14
	stopBtn.Parent = frame
	stopBtn.MouseButton1Click:Connect(function()
		Remote:FireServer("Stop")
		isPlaying = false
		isPaused = false
		playBtn.Text = "▶"
		updateNowPlaying("No song playing", "Stopped")
	end)

	-- Next Button
	local nextBtn = createButton("⏭", buttonSize, UDim2.new(0, startX + 144, 0, 0))
	nextBtn.BackgroundColor3 = COLORS.secondary
	nextBtn.TextSize = 14
	nextBtn.Parent = frame
	nextBtn.MouseButton1Click:Connect(function()
		Remote:FireServer("Next")
	end)
end

function createPlaylistSection(parent)
	local frame = Instance.new("Frame")
	frame.Name = "PlaylistSection"
	frame.Size = UDim2.new(1, -16, 0, 128)
	frame.Position = UDim2.new(0, 8, 0, 146)
	frame.BackgroundColor3 = COLORS.surface
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	-- Header
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -8, 0, 22)
	header.Position = UDim2.new(0, 6, 0, 2)
	header.BackgroundTransparency = 1
	header.Text = "📋 Playlist"
	header.TextColor3 = COLORS.text
	header.TextSize = 11
	header.Font = Enum.Font.GothamBold
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = frame

	-- Scrolling Frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ScrollFrame"
	scrollFrame.Size = UDim2.new(1, -12, 1, -28)
	scrollFrame.Position = UDim2.new(0, 6, 0, 26)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 3
	scrollFrame.ScrollBarImageColor3 = COLORS.primary
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = frame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 3)
	listLayout.Parent = scrollFrame

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
	end)
end

function createAddSongSection(parent)
	local frame = Instance.new("Frame")
	frame.Name = "AddSongSection"
	frame.Size = UDim2.new(1, -16, 0, 38)
	frame.Position = UDim2.new(0, 8, 0, 278)
	frame.BackgroundColor3 = COLORS.surface
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	-- Input
	local input = Instance.new("TextBox")
	input.Name = "Input"
	input.Size = UDim2.new(1, -72, 0, 26)
	input.Position = UDim2.new(0, 6, 0, 6)
	input.BackgroundColor3 = COLORS.background
	input.BorderSizePixel = 0
	input.TextColor3 = COLORS.text
	input.PlaceholderText = "Audio ID"
	input.PlaceholderColor3 = COLORS.textDim
	input.Text = ""
	input.TextSize = 11
	input.Font = Enum.Font.Gotham
	input.ClearTextOnFocus = false
	input.Parent = frame

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 5)
	inputCorner.Parent = input

	-- Add Button
	local addBtn = createButton("+ Add", UDim2.new(0, 60, 0, 26), UDim2.new(1, -66, 0, 6))
	addBtn.BackgroundColor3 = COLORS.success
	addBtn.TextSize = 11
	addBtn.Parent = frame
	addBtn.MouseButton1Click:Connect(function()
		local text = input.Text
		if text ~= "" then
			local audioId = text:match("%d+")
			if audioId then
				table.insert(playlist, {
					id = audioId,
					name = "Custom " .. #playlist + 1
				})
				Remote:FireServer("SetPlaylist", playlist)
				updatePlaylistDisplay()
				input.Text = ""
			end
		end
	end)
end

function createButton(text, size, position)
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.Text = text
	button.TextColor3 = COLORS.text
	button.TextSize = 14
	button.Font = Enum.Font.GothamBold
	button.BorderSizePixel = 0
	button.AutoButtonColor = false

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	button.MouseEnter:Connect(function()
		button.BackgroundTransparency = 0.2
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundTransparency = 0
	end)

	return button
end

function updatePlaylistDisplay()
	if not mainGui then return end

	local scrollFrame = mainGui.MainFrame.PlaylistSection.ScrollFrame
	scrollFrame:ClearAllChildren()

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 3)
	listLayout.Parent = scrollFrame

	for i, song in ipairs(playlist) do
		local songFrame = Instance.new("TextButton")
		songFrame.Name = "Song_" .. i
		songFrame.Size = UDim2.new(1, -6, 0, 26)
		songFrame.BackgroundColor3 = (i == currentSongIndex) and COLORS.primary or COLORS.background
		songFrame.BorderSizePixel = 0
		songFrame.AutoButtonColor = false
		songFrame.Text = ""
		songFrame.Parent = scrollFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = songFrame

		-- Song name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -30, 1, 0)
		nameLabel.Position = UDim2.new(0, 6, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = song.name
		nameLabel.TextColor3 = COLORS.text
		nameLabel.TextSize = 11
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = songFrame

		-- Delete button
		local deleteBtn = Instance.new("TextButton")
		deleteBtn.Size = UDim2.new(0, 22, 0, 22)
		deleteBtn.Position = UDim2.new(1, -24, 0.5, -11)
		deleteBtn.BackgroundColor3 = COLORS.danger
		deleteBtn.Text = "×"
		deleteBtn.TextColor3 = COLORS.text
		deleteBtn.TextSize = 14
		deleteBtn.Font = Enum.Font.GothamBold
		deleteBtn.BorderSizePixel = 0
		deleteBtn.Parent = songFrame

		local deleteCorner = Instance.new("UICorner")
		deleteCorner.CornerRadius = UDim.new(0, 5)
		deleteCorner.Parent = deleteBtn

		deleteBtn.MouseButton1Click:Connect(function()
			table.remove(playlist, i)
			Remote:FireServer("SetPlaylist", playlist)
			updatePlaylistDisplay()
		end)

		songFrame.MouseButton1Click:Connect(function()
			currentSongIndex = i
			Remote:FireServer("PlayFromPlaylist", i)
			updatePlaylistDisplay()
		end)
	end

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4)
	end)
end

function updateNowPlaying(songName, status)
	if not mainGui then return end

	local nowPlaying = mainGui.MainFrame.NowPlaying
	nowPlaying.SongName.Text = songName
	nowPlaying.Status.Text = status
end

function onRemote(action, ...)
	if action == "PlaybackState" then
		local state = ...
		if state == "playing" then
			isPlaying = true
			isPaused = false
			if mainGui then
				mainGui.MainFrame.Controls.PlayButton.Text = "⏸"
			end
		elseif state == "paused" then
			isPaused = true
		elseif state == "stopped" then
			isPlaying = false
			isPaused = false
		end

	elseif action == "SongChanged" then
		local index, songInfo = ...
		currentSongIndex = index
		if songInfo then
			updateNowPlaying(songInfo.name, "Now Playing")
			updatePlaylistDisplay()
		end
	end
end

function onEquipped()
	createMainGui()
	Remote:FireServer("SetPlaylist", playlist)
end

function onUnequipped()
	if mainGui then
		mainGui:Destroy()
		mainGui = nil
	end
end

-- Connect events
Tool.Equipped:Connect(onEquipped)
Tool.Unequipped:Connect(onUnequipped)
Remote.OnClientEvent:Connect(onRemote)