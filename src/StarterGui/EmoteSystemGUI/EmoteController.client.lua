-- ============================================================================
-- EMOTE SYSTEM WITH TOPBARPLUS
-- ============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load TopbarPlus
local Icon
local IconModule = ReplicatedStorage:WaitForChild("Icon", 10)
if IconModule then
	Icon = require(IconModule)
else
	warn("[Emote] TopbarPlus not found")
	return
end

-- Wait for animations folder
local animations = ReplicatedStorage:WaitForChild("Animations")

-- Global variables
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")
local currentAnimation = nil
local currentAnimationStoppedConnection = nil

-- UI References
local emoteGUI = script.Parent
local stopButton
local emoteFrame

-- Emote icons for TopbarPlus
local EMOTE_ICONS = {
	Deselected = "rbxassetid://130905863281467",
	Selected = "rbxassetid://130905863281467",
}

-- ============================================================================
-- FORCE STOP ALL EMOTES
-- ============================================================================
local function forceStopAllEmotes()
	if currentAnimationStoppedConnection then
		pcall(function()
			currentAnimationStoppedConnection:Disconnect()
		end)
		currentAnimationStoppedConnection = nil
	end

	if currentAnimation then
		pcall(function()
			currentAnimation:Stop()
		end)
		currentAnimation = nil
	end

	if animator then
		pcall(function()
			local tracks = animator:GetPlayingAnimationTracks()
			for _, track in ipairs(tracks) do
				if track.Priority == Enum.AnimationPriority.Action4 then
					track:Stop()
				end
			end
		end)
	end

	if stopButton then
		stopButton.Visible = false
	end
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================
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

local function isMobileDevice()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	return viewportSize.X < 800 or viewportSize.Y < 600 or UserInputService.TouchEnabled
end

-- ============================================================================
-- CREATE EMOTE UI
-- ============================================================================
local function createEmoteUI()
	if stopButton then
		stopButton:Destroy()
	end
	if emoteFrame then
		emoteFrame:Destroy()
	end

	local isMobile = isMobileDevice()

	-- STOP BUTTON (outside frame, appears when emote is active)
	stopButton = Instance.new("TextButton")
	stopButton.Name = "StopButton"
	stopButton.AnchorPoint = Vector2.new(0, 1) -- Bottom left anchor
	if isMobile then
		stopButton.Size = UDim2.new(0, 100, 0, 40)
		stopButton.Position = UDim2.new(0, 10, 1, -10) -- Bottom left corner, 10px from edges
	else
		stopButton.Size = UDim2.new(0, 110, 0, 45)
		stopButton.Position = UDim2.new(0, 15, 1, -15) -- Bottom left corner, 15px from edges
	end
	stopButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	stopButton.BackgroundTransparency = 0.4
	stopButton.BorderSizePixel = 0
	stopButton.Text = "Stop Emote"
	stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	stopButton.TextSize = isMobile and 12 or 13
	stopButton.Font = Enum.Font.GothamBold
	stopButton.Visible = false
	stopButton.Parent = emoteGUI
	local stopCorner = Instance.new("UICorner")
	stopCorner.CornerRadius = UDim.new(0, 10)
	stopCorner.Parent = stopButton
	local stopStroke = Instance.new("UIStroke")
	stopStroke.Color = Color3.fromRGB(255, 255, 255)
	stopStroke.Thickness = 1.5
	stopStroke.Transparency = 0.6
	stopStroke.Parent = stopButton

	-- MAIN FRAME
	emoteFrame = Instance.new("Frame")
	emoteFrame.Name = "EmoteFrame"
	emoteFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	if isMobile then
		emoteFrame.Size = UDim2.new(0, 320, 0, 360)
	else
		emoteFrame.Size = UDim2.new(0, 380, 0, 440)
	end
	emoteFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	emoteFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	emoteFrame.BackgroundTransparency = 0.3
	emoteFrame.BorderSizePixel = 0
	emoteFrame.Visible = false
	emoteFrame.Parent = emoteGUI
	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, isMobile and 15 or 18)
	frameCorner.Parent = emoteFrame
	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Color3.fromRGB(255, 255, 255)
	frameStroke.Thickness = 1
	frameStroke.Transparency = 0.7
	frameStroke.Parent = emoteFrame

	-- HEADER
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, isMobile and 45 or 50)
	header.BackgroundTransparency = 1
	header.Parent = emoteFrame
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "EMOTES"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = isMobile and 16 or 18
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	-- CLOSE BUTTON (X)
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, isMobile and 35 or 38, 0, isMobile and 35 or 38)
	closeButton.Position = UDim2.new(1, isMobile and -42 or -45, 0, isMobile and 5 or 6)
	closeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	closeButton.BackgroundTransparency = 0.3
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = isMobile and 16 or 18
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = header
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton
	local closeStroke = Instance.new("UIStroke")
	closeStroke.Color = Color3.fromRGB(255, 255, 255)
	closeStroke.Thickness = 1
	closeStroke.Transparency = 0.7
	closeStroke.Parent = closeButton

	-- SEARCH BAR
	local searchFrame = Instance.new("Frame")
	searchFrame.Size = UDim2.new(1, -30, 0, isMobile and 35 or 38)
	searchFrame.Position = UDim2.new(0, 15, 0, isMobile and 50 or 55)
	searchFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	searchFrame.BackgroundTransparency = 0.3
	searchFrame.BorderSizePixel = 0
	searchFrame.Parent = emoteFrame
	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 8)
	searchCorner.Parent = searchFrame
	local searchStroke = Instance.new("UIStroke")
	searchStroke.Color = Color3.fromRGB(255, 255, 255)
	searchStroke.Thickness = 1
	searchStroke.Transparency = 0.8
	searchStroke.Parent = searchFrame
	local searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(1, -15, 1, 0)
	searchBox.Position = UDim2.new(0, 10, 0, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.Text = ""
	searchBox.PlaceholderText = "🔍 Search emote..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	searchBox.TextSize = isMobile and 12 or 14
	searchBox.Font = Enum.Font.Gotham
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchFrame

	-- CATEGORY BUTTONS
	local categoryFrame = Instance.new("Frame")
	categoryFrame.Size = UDim2.new(1, -30, 0, isMobile and 32 or 35)
	categoryFrame.Position = UDim2.new(0, 15, 0, isMobile and 92 or 100)
	categoryFrame.BackgroundTransparency = 1
	categoryFrame.Parent = emoteFrame
	local categoryLayout = Instance.new("UIListLayout")
	categoryLayout.FillDirection = Enum.FillDirection.Horizontal
	categoryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	categoryLayout.Padding = UDim.new(0, 8)
	categoryLayout.Parent = categoryFrame
	local categories = { "All", "dance", "pose", "walk" }
	local selectedCategory = "All"
	local categoryButtons = {}
	for _, categoryName in ipairs(categories) do
		local catButton = Instance.new("TextButton")
		catButton.Size = UDim2.new(0, isMobile and 70 or 80, 1, 0)
		catButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		catButton.BackgroundTransparency = categoryName == "All" and 0.2 or 0.5
		catButton.BorderSizePixel = 0
		catButton.Text = categoryName:upper()
		catButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		catButton.TextSize = isMobile and 10 or 11
		catButton.Font = Enum.Font.GothamBold
		catButton.Parent = categoryFrame
		local catCorner = Instance.new("UICorner")
		catCorner.CornerRadius = UDim.new(0, 6)
		catCorner.Parent = catButton
		local catStroke = Instance.new("UIStroke")
		catStroke.Color = Color3.fromRGB(255, 255, 255)
		catStroke.Thickness = categoryName == "All" and 1.5 or 1
		catStroke.Transparency = categoryName == "All" and 0.5 or 0.8
		catStroke.Parent = catButton
		categoryButtons[categoryName] = { button = catButton, stroke = catStroke }
		catButton.MouseButton1Click:Connect(function()
			selectedCategory = categoryName
			for name, data in pairs(categoryButtons) do
				if name == categoryName then
					data.button.BackgroundTransparency = 0.2
					data.stroke.Thickness = 1.5
					data.stroke.Transparency = 0.5
				else
					data.button.BackgroundTransparency = 0.5
					data.stroke.Thickness = 1
					data.stroke.Transparency = 0.8
				end
			end
			updateEmoteList()
		end)
	end

	-- SCROLL FRAME
	local scrollFrame = Instance.new("ScrollingFrame")
	if isMobile then
		scrollFrame.Size = UDim2.new(1, -30, 1, -175)
		scrollFrame.Position = UDim2.new(0, 15, 0, 132)
	else
		scrollFrame.Size = UDim2.new(1, -30, 1, -150)
		scrollFrame.Position = UDim2.new(0, 15, 0, 142)
	end
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = isMobile and 3 or 4
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
	scrollFrame.ScrollBarImageTransparency = 0.7
	scrollFrame.Parent = emoteFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)

	-- CREATE EMOTE BUTTONS
	function updateEmoteList()
		for _, child in pairs(scrollFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		local searchText = searchBox.Text:lower()
		local animsToShow = {}

		if selectedCategory == "All" then
			for _, folder in pairs(animations:GetChildren()) do
				if folder:IsA("Folder") then
					for _, anim in pairs(folder:GetChildren()) do
						table.insert(animsToShow, { anim = anim, category = folder.Name })
					end
				end
			end
		else
			local folder = animations:FindFirstChild(selectedCategory)
			if folder then
				for _, anim in pairs(folder:GetChildren()) do
					table.insert(animsToShow, { anim = anim, category = selectedCategory })
				end
			end
		end

		table.sort(animsToShow, function(a, b)
			return naturalSortCompare(a.anim.Name, b.anim.Name)
		end)

		for i, data in ipairs(animsToShow) do
			local animName = data.anim.Name:lower()

			if searchText == "" or animName:find(searchText) then
				local emoteBtn = Instance.new("TextButton")
				emoteBtn.Size = UDim2.new(1, -10, 0, isMobile and 40 or 42)
				emoteBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				emoteBtn.BackgroundTransparency = 0.4
				emoteBtn.BorderSizePixel = 0
				emoteBtn.Text = ""
				emoteBtn.Name = data.anim.Name
				emoteBtn.LayoutOrder = i
				emoteBtn.Parent = scrollFrame

				local btnCorner = Instance.new("UICorner")
				btnCorner.CornerRadius = UDim.new(0, 8)
				btnCorner.Parent = emoteBtn

				local btnStroke = Instance.new("UIStroke")
				btnStroke.Color = Color3.fromRGB(255, 255, 255)
				btnStroke.Thickness = 1
				btnStroke.Transparency = 0.8
				btnStroke.Parent = emoteBtn

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, -80, 1, 0)
				label.Position = UDim2.new(0, 12, 0, 0)
				label.BackgroundTransparency = 1
				label.Text = data.anim.Name
				label.TextColor3 = Color3.fromRGB(255, 255, 255)
				label.TextSize = isMobile and 12 or 13
				label.Font = Enum.Font.GothamMedium
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = emoteBtn

				local tag = Instance.new("TextLabel")
				tag.Size = UDim2.new(0, 60, 0, isMobile and 20 or 22)
				tag.Position = UDim2.new(1, -68, 0.5, -11)
				tag.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				tag.BackgroundTransparency = 0.3
				tag.BorderSizePixel = 0
				tag.Text = data.category:upper()
				tag.TextColor3 = Color3.fromRGB(200, 200, 200)
				tag.TextSize = isMobile and 9 or 10
				tag.Font = Enum.Font.GothamBold
				tag.Parent = emoteBtn

				local tagCorner = Instance.new("UICorner")
				tagCorner.CornerRadius = UDim.new(0, 5)
				tagCorner.Parent = tag

				emoteBtn.MouseButton1Click:Connect(function()
					forceStopAllEmotes()

					local loadedAnim = animator:LoadAnimation(data.anim)
					loadedAnim.Looped = true
					loadedAnim.Priority = Enum.AnimationPriority.Action4
					loadedAnim:Play()
					currentAnimation = loadedAnim

					if stopButton then
						stopButton.Visible = true
					end

					currentAnimationStoppedConnection = loadedAnim.Stopped:Connect(function()
						if currentAnimation == loadedAnim then
							currentAnimation = nil
						end
						if stopButton then
							stopButton.Visible = false
						end
						currentAnimationStoppedConnection = nil
					end)

					TweenService:Create(emoteBtn, TweenInfo.new(0.1), {
						BackgroundTransparency = 0.2,
					}):Play()
					wait(0.1)
					TweenService:Create(emoteBtn, TweenInfo.new(0.2), {
						BackgroundTransparency = 0.4,
					}):Play()
				end)

				if not isMobile then
					emoteBtn.MouseEnter:Connect(function()
						TweenService:Create(emoteBtn, TweenInfo.new(0.15), {
							BackgroundTransparency = 0.25,
						}):Play()
						TweenService:Create(btnStroke, TweenInfo.new(0.15), {
							Transparency = 0.6,
						}):Play()
					end)

					emoteBtn.MouseLeave:Connect(function()
						TweenService:Create(emoteBtn, TweenInfo.new(0.15), {
							BackgroundTransparency = 0.4,
						}):Play()
						TweenService:Create(btnStroke, TweenInfo.new(0.15), {
							Transparency = 0.8,
						}):Play()
					end)
				end
			end
		end
	end

	updateEmoteList()

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		updateEmoteList()
	end)

	-- Close button
	closeButton.MouseButton1Click:Connect(function()
		emoteFrame.Visible = false
		if emoteIcon then
			emoteIcon:deselect()
		end
	end)

	-- Stop button
	stopButton.MouseButton1Click:Connect(function()
		forceStopAllEmotes()
		stopButton.Visible = false
		stopButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		stopButton.BackgroundTransparency = 0.4
	end)

	-- Hover effects (stop button)
	if not isMobile then
		stopButton.MouseEnter:Connect(function()
			TweenService:Create(stopButton, TweenInfo.new(0.2), {
				BackgroundTransparency = 0.2,
			}):Play()
			TweenService:Create(stopStroke, TweenInfo.new(0.2), {
				Transparency = 0.4,
			}):Play()
		end)
		stopButton.MouseLeave:Connect(function()
			TweenService:Create(stopButton, TweenInfo.new(0.2), {
				BackgroundTransparency = 0.4,
			}):Play()
			TweenService:Create(stopStroke, TweenInfo.new(0.2), {
				Transparency = 0.6,
			}):Play()
		end)
	end
end

-- ============================================================================
-- CREATE TOPBARPLUS ICON
-- ============================================================================
local emoteIcon

local function createTopbarIcon()
	emoteIcon = Icon.new()
	emoteIcon:setName("Emote")
	emoteIcon:setLabel("Emote")
	emoteIcon:setImage(EMOTE_ICONS.Deselected, "Deselected")
	emoteIcon:setImage(EMOTE_ICONS.Selected, "Selected")

	emoteIcon.selected:Connect(function()
		emoteFrame.Visible = true
	end)

	emoteIcon.deselected:Connect(function()
		emoteFrame.Visible = false
	end)

	return emoteIcon
end

-- ============================================================================
-- CHARACTER LIFECYCLE HANDLING
-- ============================================================================
player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = character:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")

	forceStopAllEmotes()

	currentAnimation = nil
	currentAnimationStoppedConnection = nil
end)

-- ============================================================================
-- INITIALIZE
-- ============================================================================
createEmoteUI()
task.wait(1) -- Wait for TopbarPlus to be ready
createTopbarIcon()

print("🎭 Emote System with TopbarPlus loaded!")
