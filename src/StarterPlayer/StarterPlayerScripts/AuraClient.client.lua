-- ============================================================================
-- AURA SYSTEM WITH TOPBARPLUS
-- ============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Load TopbarPlus
local Icon
local IconModule = ReplicatedStorage:WaitForChild("Icon", 10)
if IconModule then
	Icon = require(IconModule)
else
	warn("[Aura] TopbarPlus not found")
	return
end

local success, auraRemotes = pcall(function()
	return ReplicatedStorage:WaitForChild("AuraRemotes", 10)
end)

if not success or not auraRemotes then
	warn("Failed to find AuraRemotes folder")
	return
end

local auraSelectionRemote = auraRemotes:WaitForChild("AuraSelection")
local getAurasRemote = auraRemotes:WaitForChild("GetAvailableAuras")
local createAuraGUIRemote = auraRemotes:WaitForChild("CreateAuraGUI")

-- Aura icons for TopbarPlus
local AURA_ICONS = {
	Deselected = "rbxassetid://87479913643696",
	Selected = "rbxassetid://87479913643696",
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================
local function isMobileDevice()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	return viewportSize.X < 800 or viewportSize.Y < 600 or UserInputService.TouchEnabled
end

local function showNotification(text, color)
	local playerGui = player:WaitForChild("PlayerGui")

	local notificationGui = Instance.new("ScreenGui")
	notificationGui.Name = "AuraNotification"
	notificationGui.Parent = playerGui

	local isMobile = isMobileDevice()

	local notification = Instance.new("Frame")
	notification.Size = isMobile and UDim2.new(0, 280, 0, 45) or UDim2.new(0, 300, 0, 60)
	notification.Position = UDim2.new(0.5, 0, 0, -70)
	notification.AnchorPoint = Vector2.new(0.5, 0)
	notification.BackgroundColor3 = Color3.new(0, 0, 0)
	notification.BackgroundTransparency = 0.7
	notification.BorderSizePixel = 0
	notification.Parent = notificationGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = notification

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 1
	stroke.Transparency = 0.7
	stroke.Parent = notification

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = isMobile and 13 or 16
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = notification

	local tweenIn = TweenService:Create(
		notification,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 15) }
	)
	tweenIn:Play()

	spawn(function()
		wait(2.5)
		local tweenOut = TweenService:Create(
			notification,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 0, -70), BackgroundTransparency = 1 }
		)
		TweenService
			:Create(label, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 })
			:Play()
		TweenService
			:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 })
			:Play()

		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			notificationGui:Destroy()
		end)
	end)
end

-- ============================================================================
-- CREATE AURA MENU
-- ============================================================================
local auraFrame
local auraIcon

local function createAuraMenu()
	local playerGui = player:WaitForChild("PlayerGui")

	-- Destroy any existing Aura GUI (better cleanup)
	local existingAuraGUI = playerGui:FindFirstChild("AuraSystemGUI")
	if existingAuraGUI then
		existingAuraGUI:Destroy()
	end

	-- Also clean up any stray notification GUIs
	for _, obj in pairs(playerGui:GetChildren()) do
		if obj.Name == "AuraNotification" then
			obj:Destroy()
		end
	end

	local isMobile = isMobileDevice()

	local auraGUI = Instance.new("ScreenGui")
	auraGUI.Name = "AuraSystemGUI"
	auraGUI.ResetOnSpawn = false
	auraGUI.IgnoreGuiInset = true
	auraGUI.Parent = playerGui
	auraGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Main Frame
	auraFrame = Instance.new("Frame")
	auraFrame.Name = "AuraFrame"
	auraFrame.AnchorPoint = Vector2.new(0.5, 0.5)

	if isMobile then
		auraFrame.Size = UDim2.new(0, 320, 0, 280)
		auraFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	else
		auraFrame.Size = UDim2.new(0, 420, 0, 480)
		auraFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	end

	auraFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	auraFrame.BackgroundTransparency = 0.7
	auraFrame.BorderSizePixel = 0
	auraFrame.Visible = false
	auraFrame.Parent = auraGUI

	local auraCorner = Instance.new("UICorner")
	auraCorner.CornerRadius = UDim.new(0, isMobile and 15 or 20)
	auraCorner.Parent = auraFrame

	local auraStroke = Instance.new("UIStroke")
	auraStroke.Color = Color3.new(1, 1, 1)
	auraStroke.Thickness = 1
	auraStroke.Transparency = 0.7
	auraStroke.Parent = auraFrame

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, isMobile and 38 or 55)
	header.BackgroundTransparency = 1
	header.Parent = auraFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -50, 1, 0)
	title.Position = UDim2.new(0, 12, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = isMobile and "✨ Auras" or "✨ Aura Collection"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = isMobile and 16 or 20
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, isMobile and 32 or 38, 0, isMobile and 32 or 38)
	closeButton.Position = UDim2.new(1, isMobile and -38 or -45, 0, isMobile and 3 or 8)
	closeButton.BackgroundColor3 = Color3.new(0, 0, 0)
	closeButton.BackgroundTransparency = 0.7
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextSize = isMobile and 18 or 20
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = header

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeButton

	-- Subtitle (only on PC)
	if not isMobile then
		local subtitle = Instance.new("TextLabel")
		subtitle.Size = UDim2.new(1, -24, 0, 18)
		subtitle.Position = UDim2.new(0, 12, 0, 55)
		subtitle.BackgroundTransparency = 1
		subtitle.Text = "Unlock auras by reaching Summit levels"
		subtitle.TextColor3 = Color3.new(1, 1, 1)
		subtitle.TextSize = 12
		subtitle.Font = Enum.Font.Gotham
		subtitle.TextXAlignment = Enum.TextXAlignment.Left
		subtitle.TextTransparency = 0.4
		subtitle.Parent = auraFrame
	end

	-- Scroll Frame
	local scrollFrame = Instance.new("ScrollingFrame")

	if isMobile then
		scrollFrame.Size = UDim2.new(1, -16, 1, -85)
		scrollFrame.Position = UDim2.new(0, 8, 0, 42)
	else
		scrollFrame.Size = UDim2.new(1, -32, 1, -150)
		scrollFrame.Position = UDim2.new(0, 16, 0, 80)
	end

	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = isMobile and 3 or 4
	scrollFrame.ScrollBarImageColor3 = Color3.new(1, 1, 1)
	scrollFrame.ScrollBarImageTransparency = 0.7
	scrollFrame.Parent = auraFrame

	-- Layout (Grid for PC, List for Mobile)
	local layout
	if isMobile then
		layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 6)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = scrollFrame
	else
		layout = Instance.new("UIGridLayout")
		layout.CellPadding = UDim2.new(0, 8, 0, 8)
		layout.CellSize = UDim2.new(0.48, 0, 0, 90)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = scrollFrame
	end

	local availableAuras, summitValue = getAurasRemote:InvokeServer()

	-- Off Button
	local offButton = Instance.new("TextButton")

	if isMobile then
		offButton.Size = UDim2.new(0.96, 0, 0, 40)
	else
		offButton.Size = UDim2.new(1, 0, 0, 50)
	end

	offButton.BackgroundColor3 = Color3.new(0, 0, 0)
	offButton.BackgroundTransparency = 0.7
	offButton.BorderSizePixel = 0
	offButton.Text = "❌  Turn Off Aura"
	offButton.TextColor3 = Color3.new(1, 1, 1)
	offButton.TextSize = isMobile and 13 or 15
	offButton.Font = Enum.Font.GothamBold
	offButton.LayoutOrder = 0
	offButton.Parent = scrollFrame

	local offCorner = Instance.new("UICorner")
	offCorner.CornerRadius = UDim.new(0, 10)
	offCorner.Parent = offButton

	local offStroke = Instance.new("UIStroke")
	offStroke.Color = Color3.new(1, 1, 1)
	offStroke.Thickness = 1
	offStroke.Transparency = 0.7
	offStroke.Parent = offButton

	offButton.MouseButton1Click:Connect(function()
		auraSelectionRemote:FireServer("none")
		showNotification("Aura turned off")
		auraFrame.Visible = false
		if auraIcon then
			auraIcon:deselect()
		end
	end)

	-- Aura Cards
	for i, auraData in ipairs(availableAuras) do
		local auraCard = Instance.new("TextButton")

		if isMobile then
			auraCard.Size = UDim2.new(0.96, 0, 0, 46)
		end

		auraCard.BackgroundColor3 = Color3.new(0, 0, 0)
		auraCard.BackgroundTransparency = 0.7
		auraCard.BorderSizePixel = 0
		auraCard.Text = ""
		auraCard.LayoutOrder = i
		auraCard.Parent = scrollFrame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, isMobile and 10 or 12)
		cardCorner.Parent = auraCard

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Thickness = 1
		cardStroke.Transparency = auraData.unlocked and 0.6 or 0.8
		cardStroke.Color = Color3.new(1, 1, 1)
		cardStroke.Parent = auraCard

		-- Icon
		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(0, isMobile and 32 or 40, 0, isMobile and 32 or 40)
		icon.Position = UDim2.new(0, 8, 0, isMobile and 7 or 10)
		icon.BackgroundTransparency = 1
		icon.Text = auraData.unlocked and auraData.emoji or "🔒"
		icon.TextSize = isMobile and 22 or 28
		icon.Parent = auraCard
		if auraData.unlocked then
			icon.TextColor3 = auraData.color
		else
			icon.TextColor3 = Color3.fromRGB(150, 150, 150)
		end

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, isMobile and -85 or -100, 0, isMobile and 18 or 22)
		nameLabel.Position = UDim2.new(0, isMobile and 45 or 55, 0, isMobile and 4 or 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = auraData.name
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextTransparency = auraData.unlocked and 0 or 0.5
		nameLabel.TextSize = isMobile and 12 or 14
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = auraCard

		-- Requirement
		local reqLabel = Instance.new("TextLabel")
		reqLabel.Size = UDim2.new(1, isMobile and -85 or -100, 0, isMobile and 14 or 16)
		reqLabel.Position = UDim2.new(0, isMobile and 45 or 55, 1, isMobile and -18 or -22)
		reqLabel.BackgroundTransparency = 1
		reqLabel.Text = auraData.unlocked and ("Summit " .. auraData.requirement)
			or ("🔒 Need Summit " .. auraData.requirement)
		reqLabel.TextColor3 = Color3.new(1, 1, 1)
		reqLabel.TextSize = isMobile and 9 or 11
		reqLabel.Font = Enum.Font.Gotham
		reqLabel.TextXAlignment = Enum.TextXAlignment.Left
		reqLabel.TextTransparency = 0.4
		reqLabel.Parent = auraCard

		-- Badge
		if auraData.unlocked then
			local badge = Instance.new("Frame")
			badge.Size = UDim2.new(0, isMobile and 22 or 24, 0, isMobile and 22 or 24)
			badge.Position = UDim2.new(1, isMobile and -28 or -32, 0, isMobile and 4 or 8)
			badge.BackgroundColor3 = Color3.new(1, 1, 1)
			badge.BorderSizePixel = 0
			badge.Parent = auraCard

			local badgeCorner = Instance.new("UICorner")
			badgeCorner.CornerRadius = UDim.new(1, 0)
			badgeCorner.Parent = badge

			local checkmark = Instance.new("TextLabel")
			checkmark.Size = UDim2.new(1, 0, 1, 0)
			checkmark.BackgroundTransparency = 1
			checkmark.Text = "✓"
			checkmark.TextColor3 = Color3.new(0, 0, 0)
			checkmark.TextSize = isMobile and 14 or 16
			checkmark.Font = Enum.Font.GothamBold
			checkmark.Parent = badge

			auraCard.MouseButton1Click:Connect(function()
				auraSelectionRemote:FireServer(auraData.name)
				showNotification("Equipped: " .. auraData.name)
				auraFrame.Visible = false
				if auraIcon then
					auraIcon:deselect()
				end
			end)

			-- Hover (PC only)
			if not isMobile then
				auraCard.MouseEnter:Connect(function()
					TweenService:Create(auraCard, TweenInfo.new(0.2), { BackgroundTransparency = 0.5 }):Play()
					TweenService:Create(cardStroke, TweenInfo.new(0.2), { Thickness = 1.5, Transparency = 0.4 }):Play()
				end)
				auraCard.MouseLeave:Connect(function()
					TweenService:Create(auraCard, TweenInfo.new(0.2), { BackgroundTransparency = 0.7 }):Play()
					TweenService:Create(cardStroke, TweenInfo.new(0.2), { Thickness = 1, Transparency = 0.6 }):Play()
				end)
			end
		else
			auraCard.AutoButtonColor = false
		end
	end

	-- Update Canvas Size
	if isMobile then
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
		end)
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
	else
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
		end)
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end

	-- Summit Display
	local summitDisplay = Instance.new("Frame")

	if isMobile then
		summitDisplay.Size = UDim2.new(1, -16, 0, 36)
		summitDisplay.Position = UDim2.new(0, 8, 1, -40)
	else
		summitDisplay.Size = UDim2.new(1, -32, 0, 48)
		summitDisplay.Position = UDim2.new(0, 16, 1, -60)
	end

	summitDisplay.BackgroundColor3 = Color3.new(0, 0, 0)
	summitDisplay.BackgroundTransparency = 0.7
	summitDisplay.BorderSizePixel = 0
	summitDisplay.Parent = auraFrame

	local summitCorner = Instance.new("UICorner")
	summitCorner.CornerRadius = UDim.new(0, 10)
	summitCorner.Parent = summitDisplay

	local summitStroke = Instance.new("UIStroke")
	summitStroke.Color = Color3.new(1, 1, 1)
	summitStroke.Thickness = 1
	summitStroke.Transparency = 0.7
	summitStroke.Parent = summitDisplay

	local summitLabel = Instance.new("TextLabel")
	summitLabel.Size = UDim2.new(1, -16, 1, 0)
	summitLabel.Position = UDim2.new(0, 8, 0, 0)
	summitLabel.BackgroundTransparency = 1
	summitLabel.Text = "🏔️ Summit: " .. summitValue
	summitLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	summitLabel.TextSize = isMobile and 13 or 16
	summitLabel.Font = Enum.Font.GothamBold
	summitLabel.TextXAlignment = Enum.TextXAlignment.Center
	summitLabel.Parent = summitDisplay

	-- Close button
	closeButton.MouseButton1Click:Connect(function()
		auraFrame.Visible = false
		if auraIcon then
			auraIcon:deselect()
		end
	end)
end

-- ============================================================================
-- CREATE TOPBARPLUS ICON
-- ============================================================================
local function createTopbarIcon()
	-- Clean up existing icon reference
	if auraIcon then
		auraIcon:destroy()
		auraIcon = nil
	end

	-- Check for any existing icon with same name (fallback)
	local existingIcon = Icon.getIcon("Aura")
	if existingIcon then
		existingIcon:destroy()
	end

	auraIcon = Icon.new()
	auraIcon:setName("Aura")
	auraIcon:setLabel("Aura")
	auraIcon:setImage(AURA_ICONS.Deselected, "Deselected")
	auraIcon:setImage(AURA_ICONS.Selected, "Selected")

	auraIcon.selected:Connect(function()
		if auraFrame then
			auraFrame.Visible = true
		end
	end)

	auraIcon.deselected:Connect(function()
		if auraFrame then
			auraFrame.Visible = false
		end
	end)

	return auraIcon
end

-- ============================================================================
-- CLEANUP FUNCTION
-- ============================================================================
local function cleanupAuraSystem()
	-- Destroy existing GUI
	local playerGui = player:WaitForChild("PlayerGui")
	local existingAuraGUI = playerGui:FindFirstChild("AuraSystemGUI")
	if existingAuraGUI then
		existingAuraGUI:Destroy()
	end

	-- Clean up any stray notifications
	for _, obj in pairs(playerGui:GetChildren()) do
		if obj.Name == "AuraNotification" then
			obj:Destroy()
		end
	end

	-- Cleanup icon if exists
	if auraIcon then
		auraIcon:destroy()
		auraIcon = nil
	end

	-- Also check for any existing icon by name (extra safety)
	local existingIcon = Icon.getIcon("Aura")
	if existingIcon then
		existingIcon:destroy()
	end

	-- Clear frame reference
	auraFrame = nil
end

-- ============================================================================
-- INITIALIZE
-- ============================================================================
local isInitialized = false

createAuraGUIRemote.OnClientEvent:Connect(function()
	-- Cleanup existing instance first
	if isInitialized then
		cleanupAuraSystem()
	end

	createAuraMenu()
	task.wait(1) -- Wait for TopbarPlus to be ready
	createTopbarIcon()
	isInitialized = true
end)

-- Handle respawn/death
player.CharacterRemoving:Connect(function()
	-- Don't cleanup immediately - wait for respawn
	-- The server will trigger createAuraGUIRemote when character respawns
end)

print("🎨 Aura System with TopbarPlus loaded!")
