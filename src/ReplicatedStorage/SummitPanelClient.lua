-- ReplicatedStorage -> SummitPanelClient (WITH SET SUMMIT FEATURE)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local RequestRemote = script.Parent:WaitForChild("SummitAdminPanel_Request")
local GetDataRemote = script.Parent:WaitForChild("SummitAdminPanel_GetData")

local Module = {}

function Module.Open(player)
	local PlayerGui = player:WaitForChild("PlayerGui")

	local existing = PlayerGui:FindFirstChild("SummitAdminPanel")
	if existing then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SummitAdminPanel"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 100

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 750, 0, 500) -- 🔥 Slightly wider for 2 buttons
	mainFrame.Position = UDim2.new(0.5, -375, 0.5, -250)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = mainFrame

	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Position = UDim2.new(0, -15, 0, -15)
	shadow.Size = UDim2.new(1, 30, 1, 30)
	shadow.ZIndex = 0
	shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.5
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.Parent = mainFrame

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	local headerCover = Instance.new("Frame")
	headerCover.Size = UDim2.new(1, 0, 0, 12)
	headerCover.Position = UDim2.new(0, 0, 1, -12)
	headerCover.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
	headerCover.BorderSizePixel = 0
	headerCover.Parent = header

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -100, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🏔️ SUMMIT ADMIN PANEL"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -45, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 20, 60)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 18
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = header

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 8)
	closeBtnCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	local searchFrame = Instance.new("Frame")
	searchFrame.Name = "SearchFrame"
	searchFrame.Size = UDim2.new(1, -30, 0, 40)
	searchFrame.Position = UDim2.new(0, 15, 0, 60)
	searchFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	searchFrame.BorderSizePixel = 0
	searchFrame.Parent = mainFrame

	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 8)
	searchCorner.Parent = searchFrame

	local searchBox = Instance.new("TextBox")
	searchBox.Name = "SearchBox"
	searchBox.Size = UDim2.new(1, -50, 1, 0)
	searchBox.Position = UDim2.new(0, 40, 0, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.PlaceholderText = "Cari player..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	searchBox.Text = ""
	searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	searchBox.TextSize = 16
	searchBox.Font = Enum.Font.Gotham
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchFrame

	local searchIcon = Instance.new("TextLabel")
	searchIcon.Size = UDim2.new(0, 30, 1, 0)
	searchIcon.Position = UDim2.new(0, 10, 0, 0)
	searchIcon.BackgroundTransparency = 1
	searchIcon.Text = "🔍"
	searchIcon.TextSize = 18
	searchIcon.Parent = searchFrame

	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Name = "RefreshButton"
	refreshBtn.Size = UDim2.new(0, 35, 0, 35)
	refreshBtn.Position = UDim2.new(1, -40, 0, 2.5)
	refreshBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
	refreshBtn.Text = "🔄"
	refreshBtn.TextSize = 18
	refreshBtn.BorderSizePixel = 0
	refreshBtn.Parent = searchFrame

	local refreshCorner = Instance.new("UICorner")
	refreshCorner.CornerRadius = UDim.new(0, 6)
	refreshCorner.Parent = refreshBtn

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "PlayerList"
	listFrame.Size = UDim2.new(1, -30, 1, -180)
	listFrame.Position = UDim2.new(0, 15, 0, 110)
	listFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 8
	listFrame.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
	listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.Parent = mainFrame

	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 8)
	listCorner.Parent = listFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = listFrame

	local footer = Instance.new("TextLabel")
	footer.Name = "Footer"
	footer.Size = UDim2.new(1, 0, 0, 30)
	footer.Position = UDim2.new(0, 0, 1, -35)
	footer.BackgroundTransparency = 1
	footer.Text = "💡 Set CP untuk checkpoint | Set Summit untuk jumlah summit"
	footer.TextColor3 = Color3.fromRGB(200, 200, 200)
	footer.TextSize = 14
	footer.Font = Enum.Font.Gotham
	footer.Parent = mainFrame

	local dragging = false
	local dragInput, mousePos, framePos

	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			mousePos = input.Position
			framePos = mainFrame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	header.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			mainFrame.Position = UDim2.new(
				framePos.X.Scale,
				framePos.X.Offset + delta.X,
				framePos.Y.Scale,
				framePos.Y.Offset + delta.Y
			)
		end
	end)

	local function createPlayerCard(data)
		local card = Instance.new("Frame")
		card.Name = data.Name
		card.Size = UDim2.new(1, -10, 0, 70)
		card.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
		card.BorderSizePixel = 0

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 6)
		cardCorner.Parent = card

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.3, -10, 0, 25)
		nameLabel.Position = UDim2.new(0, 10, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = data.DisplayName
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 16
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = card

		local usernameLabel = Instance.new("TextLabel")
		usernameLabel.Size = UDim2.new(0.3, -10, 0, 20)
		usernameLabel.Position = UDim2.new(0, 10, 0, 28)
		usernameLabel.BackgroundTransparency = 1
		usernameLabel.Text = "@" .. data.Name
		usernameLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		usernameLabel.TextSize = 13
		usernameLabel.Font = Enum.Font.Gotham
		usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
		usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		usernameLabel.Parent = card

		local cpLabel = Instance.new("TextLabel")
		cpLabel.Size = UDim2.new(0.2, 0, 0, 25)
		cpLabel.Position = UDim2.new(0.3, 0, 0, 8)
		cpLabel.BackgroundTransparency = 1
		cpLabel.Text = "📍 " .. data.CurrentCP
		cpLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		cpLabel.TextSize = 15
		cpLabel.Font = Enum.Font.GothamBold
		cpLabel.TextXAlignment = Enum.TextXAlignment.Center
		cpLabel.Parent = card

		local summitLabel = Instance.new("TextLabel")
		summitLabel.Size = UDim2.new(0.2, 0, 0, 20)
		summitLabel.Position = UDim2.new(0.3, 0, 0, 35)
		summitLabel.BackgroundTransparency = 1
		summitLabel.Text = "🏔️ " .. tostring(data.Summits)
		summitLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		summitLabel.TextSize = 13
		summitLabel.Font = Enum.Font.Gotham
		summitLabel.TextXAlignment = Enum.TextXAlignment.Center
		summitLabel.Parent = card

		-- 🔥 2 BUTTONS SIDE BY SIDE
		local setCPBtn = Instance.new("TextButton")
		setCPBtn.Size = UDim2.new(0, 105, 0, 50)
		setCPBtn.Position = UDim2.new(1, -230, 0.5, -25)
		setCPBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
		setCPBtn.Text = "📍 SET CP"
		setCPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		setCPBtn.TextSize = 15
		setCPBtn.Font = Enum.Font.GothamBold
		setCPBtn.BorderSizePixel = 0
		setCPBtn.Parent = card

		local setCPCorner = Instance.new("UICorner")
		setCPCorner.CornerRadius = UDim.new(0, 8)
		setCPCorner.Parent = setCPBtn

		-- 🔥 NEW: SET SUMMIT BUTTON
		local setSummitBtn = Instance.new("TextButton")
		setSummitBtn.Size = UDim2.new(0, 105, 0, 50)
		setSummitBtn.Position = UDim2.new(1, -115, 0.5, -25)
		setSummitBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
		setSummitBtn.Text = "🏔️ SET SUM"
		setSummitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		setSummitBtn.TextSize = 15
		setSummitBtn.Font = Enum.Font.GothamBold
		setSummitBtn.BorderSizePixel = 0
		setSummitBtn.Parent = card

		local setSummitCorner = Instance.new("UICorner")
		setSummitCorner.CornerRadius = UDim.new(0, 8)
		setSummitCorner.Parent = setSummitBtn

		-- Hover effects
		setCPBtn.MouseEnter:Connect(function()
			TweenService:Create(setCPBtn, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(90, 150, 200)
			}):Play()
		end)

		setCPBtn.MouseLeave:Connect(function()
			TweenService:Create(setCPBtn, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(70, 130, 180)
			}):Play()
		end)

		setSummitBtn.MouseEnter:Connect(function()
			TweenService:Create(setSummitBtn, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(255, 185, 50)
			}):Play()
		end)

		setSummitBtn.MouseLeave:Connect(function()
			TweenService:Create(setSummitBtn, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(255, 165, 0)
			}):Play()
		end)

		-- Click handlers
		setCPBtn.MouseButton1Click:Connect(function()
			Module.ShowCPSelector(player, data.Name)
		end)

		setSummitBtn.MouseButton1Click:Connect(function()
			Module.ShowSummitInput(player, data.Name, data.Summits)
		end)

		return card
	end

	function Module.RefreshData(player, listFrame, searchBox)
		for _, child in ipairs(listFrame:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		local result = GetDataRemote:InvokeServer()

		if not result or not result.success then
			return
		end

		local searchTerm = searchBox.Text:lower()

		for _, data in ipairs(result.players) do
			if searchTerm == "" or data.Name:lower():find(searchTerm) or data.DisplayName:lower():find(searchTerm) then
				local card = createPlayerCard(data)
				card.Parent = listFrame
			end
		end
	end

	Module.RefreshData(player, listFrame, searchBox)

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		Module.RefreshData(player, listFrame, searchBox)
	end)

	refreshBtn.MouseButton1Click:Connect(function()
		local tween = TweenService:Create(refreshBtn, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
			Rotation = 360
		})
		tween:Play()
		tween.Completed:Connect(function()
			refreshBtn.Rotation = 0
		end)

		Module.RefreshData(player, listFrame, searchBox)
	end)

	screenGui.Parent = PlayerGui
end

-- CP Selector Dialog
function Module.ShowCPSelector(player, targetName)
	local PlayerGui = player:WaitForChild("PlayerGui")

	local existing = PlayerGui:FindFirstChild("CPSelector")
	if existing then
		existing:Destroy()
	end

	local result = GetDataRemote:InvokeServer()
	if not result or not result.success then
		return
	end

	local checkpoints = result.checkpoints

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CPSelector"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 110

	local backdrop = Instance.new("TextButton")
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel = 0
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.Parent = screenGui

	local dialog = Instance.new("Frame")
	dialog.Size = UDim2.new(0, 400, 0, 450)
	dialog.Position = UDim2.new(0.5, -200, 0.5, -225)
	dialog.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	dialog.BorderSizePixel = 0
	dialog.Parent = screenGui

	local dialogCorner = Instance.new("UICorner")
	dialogCorner.CornerRadius = UDim.new(0, 12)
	dialogCorner.Parent = dialog

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
	header.BorderSizePixel = 0
	header.Text = "📍 Set Checkpoint: " .. targetName
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.TextSize = 17
	header.Font = Enum.Font.GothamBold
	header.Parent = dialog

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	local headerCover = Instance.new("Frame")
	headerCover.Size = UDim2.new(1, 0, 0, 12)
	headerCover.Position = UDim2.new(0, 0, 1, -12)
	headerCover.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
	headerCover.BorderSizePixel = 0
	headerCover.Parent = header

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -30, 1, -120)
	scrollFrame.Position = UDim2.new(0, 15, 0, 60)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = dialog

	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = scrollFrame

	local cpLayout = Instance.new("UIListLayout")
	cpLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cpLayout.Padding = UDim.new(0, 5)
	cpLayout.Parent = scrollFrame

	for _, cpName in ipairs(checkpoints) do
		local cpBtn = Instance.new("TextButton")
		cpBtn.Size = UDim2.new(1, -10, 0, 40)
		cpBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		cpBtn.Text = cpName == "Spawn" and "🏠 Spawn" or ("📍 " .. cpName)
		cpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		cpBtn.TextSize = 16
		cpBtn.Font = Enum.Font.GothamBold
		cpBtn.BorderSizePixel = 0
		cpBtn.Parent = scrollFrame

		local cpCorner = Instance.new("UICorner")
		cpCorner.CornerRadius = UDim.new(0, 6)
		cpCorner.Parent = cpBtn

		cpBtn.MouseEnter:Connect(function()
			TweenService:Create(cpBtn, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(70, 130, 180)
			}):Play()
		end)

		cpBtn.MouseLeave:Connect(function()
			TweenService:Create(cpBtn, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(50, 50, 55)
			}):Play()
		end)

		cpBtn.MouseButton1Click:Connect(function()
			RequestRemote:FireServer("SetCheckpoint", targetName, cpName)
			screenGui:Destroy()

			task.wait(0.2)
			local mainPanel = PlayerGui:FindFirstChild("SummitAdminPanel")
			if mainPanel then
				local listFrame = mainPanel.MainFrame.PlayerList
				local searchBox = mainPanel.MainFrame.SearchFrame.SearchBox
				Module.RefreshData(player, listFrame, searchBox)
			end
		end)
	end

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(1, -30, 0, 45)
	cancelBtn.Position = UDim2.new(0, 15, 1, -55)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(220, 20, 60)
	cancelBtn.Text = "❌ Cancel"
	cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelBtn.TextSize = 16
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.BorderSizePixel = 0
	cancelBtn.Parent = dialog

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 8)
	cancelCorner.Parent = cancelBtn

	cancelBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	backdrop.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	screenGui.Parent = PlayerGui
end

-- 🔥 NEW: SUMMIT INPUT DIALOG
function Module.ShowSummitInput(player, targetName, currentSummits)
	local PlayerGui = player:WaitForChild("PlayerGui")

	local existing = PlayerGui:FindFirstChild("SummitInputDialog")
	if existing then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SummitInputDialog"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 110

	local backdrop = Instance.new("TextButton")
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel = 0
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.Parent = screenGui

	local dialog = Instance.new("Frame")
	dialog.Size = UDim2.new(0, 400, 0, 280)
	dialog.Position = UDim2.new(0.5, -200, 0.5, -140)
	dialog.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	dialog.BorderSizePixel = 0
	dialog.Parent = screenGui

	local dialogCorner = Instance.new("UICorner")
	dialogCorner.CornerRadius = UDim.new(0, 12)
	dialogCorner.Parent = dialog

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
	header.BorderSizePixel = 0
	header.Text = "🏔️ Set Summit: " .. targetName
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.TextSize = 18
	header.Font = Enum.Font.GothamBold
	header.Parent = dialog

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	local headerCover = Instance.new("Frame")
	headerCover.Size = UDim2.new(1, 0, 0, 12)
	headerCover.Position = UDim2.new(0, 0, 1, -12)
	headerCover.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
	headerCover.BorderSizePixel = 0
	headerCover.Parent = header

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, -30, 0, 35)
	infoLabel.Position = UDim2.new(0, 15, 0, 60)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "Current Summits: " .. tostring(currentSummits)
	infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	infoLabel.TextSize = 15
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.Parent = dialog

	local inputFrame = Instance.new("Frame")
	inputFrame.Size = UDim2.new(1, -30, 0, 50)
	inputFrame.Position = UDim2.new(0, 15, 0, 105)
	inputFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	inputFrame.BorderSizePixel = 0
	inputFrame.Parent = dialog

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 8)
	inputCorner.Parent = inputFrame

	local inputBox = Instance.new("TextBox")
	inputBox.Size = UDim2.new(1, -20, 1, 0)
	inputBox.Position = UDim2.new(0, 10, 0, 0)
	inputBox.BackgroundTransparency = 1
	inputBox.PlaceholderText = "Masukkan jumlah summit (0-100000)"
	inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
	inputBox.Text = ""
	inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	inputBox.TextSize = 16
	inputBox.Font = Enum.Font.Gotham
	inputBox.TextXAlignment = Enum.TextXAlignment.Left
	inputBox.ClearTextOnFocus = false
	inputBox.Parent = inputFrame

	-- 🔥 VALIDATION: Only allow numbers
	inputBox:GetPropertyChangedSignal("Text"):Connect(function()
		inputBox.Text = string.gsub(inputBox.Text, "%D", "")
	end)

	local warningLabel = Instance.new("TextLabel")
	warningLabel.Size = UDim2.new(1, -30, 0, 20)
	warningLabel.Position = UDim2.new(0, 15, 0, 165)
	warningLabel.BackgroundTransparency = 1
	warningLabel.Text = ""
	warningLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	warningLabel.TextSize = 13
	warningLabel.Font = Enum.Font.Gotham
	warningLabel.TextXAlignment = Enum.TextXAlignment.Center
	warningLabel.Parent = dialog

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Size = UDim2.new(1, -220, 0, 45)
	confirmBtn.Position = UDim2.new(0, 15, 1, -55)
	confirmBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
	confirmBtn.Text = "✓ Set Summit"
	confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmBtn.TextSize = 16
	confirmBtn.Font = Enum.Font.GothamBold
	confirmBtn.BorderSizePixel = 0
	confirmBtn.Parent = dialog

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 8)
	confirmCorner.Parent = confirmBtn

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0, 180, 0, 45)
	cancelBtn.Position = UDim2.new(1, -195, 1, -55)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(220, 20, 60)
	cancelBtn.Text = "❌ Cancel"
	cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelBtn.TextSize = 16
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.BorderSizePixel = 0
	cancelBtn.Parent = dialog

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 8)
	cancelCorner.Parent = cancelBtn

	-- 🔥 CONFIRM BUTTON LOGIC
	local debounce = false
	confirmBtn.MouseButton1Click:Connect(function()
		if debounce then return end

		local inputText = inputBox.Text
		local amount = tonumber(inputText)

		-- Validation
		if not amount then
			warningLabel.Text = "⚠️ Input tidak valid!"
			return
		end

		if amount < 0 then
			warningLabel.Text = "⚠️ Tidak boleh negatif!"
			return
		end

		if amount > 100000 then
			warningLabel.Text = "⚠️ Maximum 100000!"
			return
		end

		debounce = true

		-- 🔥 CONFIRMATION untuk nilai > 10000
		if amount > 10000 then
			warningLabel.Text = "⚠️ Nilai besar! Klik lagi untuk konfirmasi"
			warningLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
			confirmBtn.Text = "⚠️ KONFIRMASI?"

			task.wait(2)

			-- Reset jika tidak confirm
			if debounce then
				debounce = false
				warningLabel.Text = ""
				confirmBtn.Text = "✓ Set Summit"
				return
			end
		end

		-- Send request
		RequestRemote:FireServer("SetSummit", targetName, amount)

		screenGui:Destroy()

		task.wait(0.2)
		local mainPanel = PlayerGui:FindFirstChild("SummitAdminPanel")
		if mainPanel then
			local listFrame = mainPanel.MainFrame.PlayerList
			local searchBox = mainPanel.MainFrame.SearchFrame.SearchBox
			Module.RefreshData(player, listFrame, searchBox)
		end
	end)

	cancelBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	backdrop.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	screenGui.Parent = PlayerGui
end

return Module