-- Reset to Basecamp - TopbarPlus Integration
-- Shows topbar button when player reaches summit
-- Place in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load TopbarPlus Icon
local Icon
local IconModule = ReplicatedStorage:WaitForChild("Icon", 10)
if IconModule then
	Icon = require(IconModule)
else
	warn("[ResetToBasecamp] TopbarPlus not found")
	return
end

-- Wait for RemoteEvent and RemoteFunction
local resetToBasecampRemote = ReplicatedStorage:WaitForChild("ResetToBasecamp", 10)
local checkSummitStatusRemote = ReplicatedStorage:WaitForChild("CheckSummitStatus", 10)

if not resetToBasecampRemote or not checkSummitStatusRemote then
	warn("[ResetToBasecamp] Remotes not found")
	return
end

-- Create ScreenGui for confirmation dialog
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ResetToBasecampGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 200
screenGui.Parent = playerGui

-- Topbar Icon (will be created later)
local resetIcon = nil

-- Create Confirmation Dialog (Simplified)
local confirmationDialog = Instance.new("Frame")
confirmationDialog.Name = "ConfirmationDialog"
confirmationDialog.Size = UDim2.new(0, 300, 0, 120)
confirmationDialog.Position = UDim2.new(0.5, -150, 0.5, -60)
confirmationDialog.AnchorPoint = Vector2.new(0.5, 0.5)
confirmationDialog.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
confirmationDialog.BorderSizePixel = 2
confirmationDialog.BorderColor3 = Color3.fromRGB(220, 50, 50)
confirmationDialog.Visible = false
confirmationDialog.ZIndex = 300
confirmationDialog.Parent = screenGui

local dialogCorner = Instance.new("UICorner")
dialogCorner.CornerRadius = UDim.new(0, 8)
dialogCorner.Parent = confirmationDialog

-- Dialog Message
local dialogMessage = Instance.new("TextLabel")
dialogMessage.Name = "Message"
dialogMessage.Size = UDim2.new(1, -20, 0, 50)
dialogMessage.Position = UDim2.new(0, 10, 0, 10)
dialogMessage.BackgroundTransparency = 1
dialogMessage.Text = "Reset ke basecamp?\nProgress akan hilang!"
dialogMessage.TextColor3 = Color3.fromRGB(255, 255, 255)
dialogMessage.TextStrokeTransparency = 0
dialogMessage.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
dialogMessage.Font = Enum.Font.GothamBold
dialogMessage.TextSize = 14
dialogMessage.TextXAlignment = Enum.TextXAlignment.Center
dialogMessage.TextYAlignment = Enum.TextYAlignment.Center
dialogMessage.TextWrapped = true
dialogMessage.ZIndex = 301
dialogMessage.Parent = confirmationDialog

-- Button Container
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(1, -20, 0, 40)
buttonContainer.Position = UDim2.new(0, 10, 1, -50)
buttonContainer.BackgroundTransparency = 1
buttonContainer.ZIndex = 301
buttonContainer.Parent = confirmationDialog

-- Yes Button
local yesButton = Instance.new("TextButton")
yesButton.Name = "YesButton"
yesButton.Size = UDim2.new(0.48, 0, 1, 0)
yesButton.Position = UDim2.new(0, 0, 0, 0)
yesButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
yesButton.BorderSizePixel = 0
yesButton.Text = "YA"
yesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
yesButton.TextStrokeTransparency = 0
yesButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
yesButton.Font = Enum.Font.GothamBold
yesButton.TextSize = 13
yesButton.AutoButtonColor = false
yesButton.ZIndex = 302
yesButton.Parent = buttonContainer

local yesCorner = Instance.new("UICorner")
yesCorner.CornerRadius = UDim.new(0, 6)
yesCorner.Parent = yesButton

-- No Button
local noButton = Instance.new("TextButton")
noButton.Name = "NoButton"
noButton.Size = UDim2.new(0.48, 0, 1, 0)
noButton.Position = UDim2.new(0.52, 0, 0, 0)
noButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
noButton.BorderSizePixel = 0
noButton.Text = "TIDAK"
noButton.TextColor3 = Color3.fromRGB(255, 255, 255)
noButton.TextStrokeTransparency = 0
noButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
noButton.Font = Enum.Font.GothamBold
noButton.TextSize = 13
noButton.AutoButtonColor = false
noButton.ZIndex = 302
noButton.Parent = buttonContainer

local noCorner = Instance.new("UICorner")
noCorner.CornerRadius = UDim.new(0, 6)
noCorner.Parent = noButton

-- Button hover effects
yesButton.MouseEnter:Connect(function()
	yesButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
end)

yesButton.MouseLeave:Connect(function()
	yesButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
end)

noButton.MouseEnter:Connect(function()
	noButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
end)

noButton.MouseLeave:Connect(function()
	noButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
end)

-- ============================================================================
-- CREATE TOPBAR ICON
-- ============================================================================
local function createResetIcon()
	resetIcon = Icon.new()
	resetIcon:setName("ResetToBasecamp")
	resetIcon:setLabel("RESET TO BASECAMP") -- Text only, no icon

	-- Initially hidden (will show when at summit)
	resetIcon:setEnabled(false)

	-- Click handler - show confirmation dialog
	resetIcon.selected:Connect(function()
		-- Show confirmation dialog
		confirmationDialog.Visible = true

		-- Deselect icon immediately (not a toggle button)
		task.wait()
		resetIcon:deselect()
	end)

	return resetIcon
end

-- Yes button handler
yesButton.MouseButton1Click:Connect(function()
	-- Player confirmed Reset to Basecamp

	-- Hide dialog
	confirmationDialog.Visible = false

	-- Update icon label temporarily
	if resetIcon then
		resetIcon:setLabel("Resetting...")
	end

	-- Fire remote event
	local success, err = pcall(function()
		resetToBasecampRemote:FireServer()
	end)

	if success then
		-- Reset request sent to server
		-- Icon will be hidden by the status check after teleport
		task.wait(1)
		if resetIcon then
			resetIcon:setLabel("RESET TO BASECAMP")
		end
	else
		-- Failed to send reset request
		warn("[ResetToBasecamp] Failed to reset:", err)
		if resetIcon then
			resetIcon:setLabel("RESET TO BASECAMP")
		end
	end
end)

-- No button handler
noButton.MouseButton1Click:Connect(function()
	-- Player cancelled Reset to Basecamp
	confirmationDialog.Visible = false
end)

-- Function to check summit status and update icon visibility
local function updateIconVisibility()
	if not resetIcon then return end

	local success, isAtSummit = pcall(function()
		return checkSummitStatusRemote:InvokeServer()
	end)

	if success and isAtSummit then
		-- Show icon when at summit
		resetIcon:setEnabled(true)
	else
		-- Hide icon when not at summit
		resetIcon:setEnabled(false)
	end
end

-- ============================================================================
-- INITIALIZE
-- ============================================================================
task.wait(1) -- Wait for TopbarPlus to be ready

-- Create topbar icon
createResetIcon()

-- Check status when character spawns
player.CharacterAdded:Connect(function(character)
	-- Wait a bit for server to set up everything
	task.wait(1)
	updateIconVisibility()
end)

-- Initial check if character already exists
if player.Character then
	task.wait(1)
	updateIconVisibility()
end

-- Monitor checkpoint changes to update icon visibility
local function monitorCheckpoint()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		return
	end

	local checkpointVal = leaderstats:FindFirstChild("Checkpoint")
	if checkpointVal then
		checkpointVal.Changed:Connect(function(newValue)
			task.wait(0.5) -- Small delay to let server update
			updateIconVisibility()
		end)
	end
end

monitorCheckpoint()

-- Periodic check as backup (every 5 seconds)
task.spawn(function()
	while task.wait(5) do
		updateIconVisibility()
	end
end)

print("✅ [ResetToBasecamp] Reset to Basecamp topbar button loaded!")
