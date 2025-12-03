-- Simple Reset Script - Region-based Detection Version
-- Uses the actual part size from Studio (manual resize supported)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local resetToBasecampRemote = game:WaitForChild("ReplicatedStorage"):WaitForChild("ResetToBasecamp", 5)

-- Configuration
local DETECTION_INTERVAL = 0.1 -- Check every 100ms for responsive detection
local REGION_THRESHOLD = 0.5 -- Extra margin around part size (0.5 studs)

-- Variables
local screenGui = nil
local countdownLabel = nil
local isCountingDown = false
local inRegion = false -- player sedang di dalam region
local detectionLoop = nil -- For region checking loop
local character = nil
local humanoidRootPart = nil
local currentResetPart = nil
local regionSize = nil -- Dynamic size based on actual part

-- GUI Variables
local resetLabelBillboard = nil -- For "Reset To Basecamp" text
local textResetPart = nil -- Reference to TextReset part

-- Cleanup function to properly reset all states
local function cleanup()
	-- Cancel any ongoing countdown
	if isCountingDown then
		isCountingDown = false
	end

	-- Remove UI
	if screenGui then
		screenGui:Destroy()
		screenGui = nil
		countdownLabel = nil
	end

	-- Remove Reset Label Billboard
	if resetLabelBillboard then
		resetLabelBillboard:Destroy()
		resetLabelBillboard = nil
	end

	-- Stop detection loop
	if detectionLoop then
		detectionLoop:Disconnect()
		detectionLoop = nil
	end

	-- Reset state
	inRegion = false
	currentResetPart = nil
	regionSize = nil
	textResetPart = nil
end

-----------------------------------------------------
-- UI
-----------------------------------------------------
local function createCountdownUI()
	if screenGui then
		screenGui:Destroy()
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ResetCountdownGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	countdownLabel = Instance.new("TextLabel")
	countdownLabel.Size = UDim2.new(0, 400, 0, 80)
	countdownLabel.Position = UDim2.new(0.5, -200, 0.4, -40)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.TextColor3 = Color3.new(1, 1, 1)
	countdownLabel.TextStrokeTransparency = 0
	countdownLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	countdownLabel.Font = Enum.Font.FredokaOne
	countdownLabel.TextSize = 30
	countdownLabel.TextXAlignment = Enum.TextXAlignment.Center
	countdownLabel.TextYAlignment = Enum.TextYAlignment.Center
	countdownLabel.Parent = screenGui
end

local function cancelCountdown()
	if not isCountingDown then
		return
	end
	isCountingDown = false
	if screenGui then
		screenGui:Destroy()
		screenGui = nil
	end
end

-----------------------------------------------------
-- Countdown (requires player to stay touching)
-----------------------------------------------------
local function startCountdown()
	if isCountingDown then
		return
	end
	isCountingDown = true

	createCountdownUI()

	task.spawn(function()
		for i = 3, 1, -1 do
			if not isCountingDown then
				return
			end
			if not inRegion then
				cancelCountdown()
				return
			end

			countdownLabel.Text = "Resetting to basecamp " .. i
			task.wait(1)
		end

		if isCountingDown and inRegion then
			resetToBasecampRemote:FireServer()
		end

		cancelCountdown()
	end)
end

-----------------------------------------------------
-- RESET LABEL GUI
-----------------------------------------------------
local function createResetLabelGUI(part)
	if resetLabelBillboard then
		resetLabelBillboard:Destroy()
	end

	-- Find TextReset part
	textResetPart = part:FindFirstChild("TextReset")
	if not textResetPart then
		warn("SimpleResetScript: TextReset part not found in ResetPart")
		return
	end

	-- Create BillboardGui
	resetLabelBillboard = Instance.new("BillboardGui")
	resetLabelBillboard.Name = "ResetLabel"
	resetLabelBillboard.Parent = textResetPart
	resetLabelBillboard.Size = UDim2.new(0, 300, 0, 50)
	resetLabelBillboard.StudsOffset = Vector3.new(0, 4, 0) -- 4 studs above TextReset
	resetLabelBillboard.AlwaysOnTop = true
	resetLabelBillboard.MaxDistance = 50 -- Visible within 50 studs

	-- Text Label Only
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1 -- No background
	label.Text = "Reset To Basecamp"
	label.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
	label.TextSize = 26 -- Slightly larger for better visibility
	label.Font = Enum.Font.FredokaOne
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextStrokeTransparency = 0 -- Thin black outline
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextScaled = false -- Don't scale automatically
	label.Parent = resetLabelBillboard

	-- Add floating animation
	local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local tween = game:GetService("TweenService"):Create(
		resetLabelBillboard,
		tweenInfo,
		{ StudsOffset = Vector3.new(0, 6, 0) } -- Float between 10 and 6 studs
	)
	tween:Play()
end

-----------------------------------------------------
-- Region-based Detection (supports manual part resize)
-----------------------------------------------------
local function isPlayerInRegion(partPosition, partSize)
	if not humanoidRootPart or not character or character.Parent ~= workspace then
		return false
	end

	-- Get the actual part size (including manual resize in Studio)
	local halfSize = partSize / 2
	local playerPos = humanoidRootPart.Position

	-- Check if player is within region bounds (with threshold)
	local inBoundsX = math.abs(playerPos.X - partPosition.X) <= (halfSize.X + REGION_THRESHOLD)
	local inBoundsY = math.abs(playerPos.Y - partPosition.Y) <= (halfSize.Y + REGION_THRESHOLD)
	local inBoundsZ = math.abs(playerPos.Z - partPosition.Z) <= (halfSize.Z + REGION_THRESHOLD)

	return inBoundsX and inBoundsY and inBoundsZ
end

local function bindRegionLogic(part)
	-- Stop existing detection loop
	if detectionLoop then
		detectionLoop:Disconnect()
		detectionLoop = nil
	end

	currentResetPart = part
	regionSize = part.Size -- Use actual part size from Studio

	-- Create the "Reset To Basecamp" label
	createResetLabelGUI(part)

	-- Region detection loop
	detectionLoop = RunService.Heartbeat:Connect(function()
		if not currentResetPart or not character or character.Parent ~= workspace then
			if inRegion then
				inRegion = false
				cancelCountdown()
			end
			return
		end

		local currentlyInRegion = isPlayerInRegion(currentResetPart.Position, regionSize)

		-- State transitions
		if currentlyInRegion and not inRegion then
			-- Player entered region
			inRegion = true
			if not isCountingDown then
				startCountdown()
			end
		elseif not currentlyInRegion and inRegion then
			-- Player left region
			inRegion = false
			cancelCountdown()
		end
		-- If currentlyInRegion and inRegion -> continue existing countdown
	end)
end

-----------------------------------------------------
-- Character Setup
-----------------------------------------------------
local function setupCharacter(newCharacter)
	-- Cleanup previous state
	cleanup()

	character = newCharacter
	if not character then
		return
	end

	-- Wait for HumanoidRootPart
	humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoidRootPart then
		warn("SimpleResetScript: Could not find HumanoidRootPart")
		return
	end

	-- Start looking for reset part
	task.spawn(function()
		while character and character.Parent == workspace do
			local resetFolder = workspace:FindFirstChild("ResetBasecamp", true)
			if resetFolder then
				local part = resetFolder:FindFirstChild("ResetPart")
				if part and part:IsA("BasePart") and part ~= currentResetPart then
					bindRegionLogic(part)
				end
			end
			task.wait(0.5)
		end
	end)
end

-----------------------------------------------------
-- Character Handlers
-----------------------------------------------------
-- Handle initial character
if player.Character then
	setupCharacter(player.Character)
end

-- Handle character added (spawn, respawn)
player.CharacterAdded:Connect(function(newCharacter)
	task.wait(0.1) -- Small delay to ensure character is fully loaded
	setupCharacter(newCharacter)
end)

-- Handle character removing (death, reset)
player.CharacterRemoving:Connect(function()
	cleanup()
end)

-----------------------------------------------------
-- Find ResetPart (Legacy - kept for compatibility)
-----------------------------------------------------
--[[
task.spawn(function()
	while task.wait(0.5) do
		local resetFolder = workspace:FindFirstChild("ResetBasecamp", true)
		if resetFolder then
			local part = resetFolder:FindFirstChild("ResetPart")
			if part and part:IsA("BasePart") then
				bindTouchLogic(part)
				break
			end
		end
	end
end)
--]]
