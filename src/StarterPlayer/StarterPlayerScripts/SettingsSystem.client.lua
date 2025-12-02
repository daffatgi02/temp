-- ============================================================================
-- SETTINGS SYSTEM WITH TOPBARPLUS
-- ============================================================================
-- Settings button with toggles for Title visibility and GUI visibility

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
	warn("[Settings] TopbarPlus not found anywhere..")
	return
end

-- Settings icons
local SETTINGS_ICONS = {
	Deselected = "rbxassetid://104303552767511", -- Gear unselected
	Selected = "rbxassetid://94091537936915", -- Gear selected
}

-- State
local settingsGui = nil
local isVisible = false

-- Settings state (saved per player session)
local settingsState = {
	titlesVisible = true, -- Default: titles shown
	guiVisible = true, -- Default: GUI shown
	playersVisible = true, -- Default: players shown
	lowGraphicsMode = false, -- Default: low graphics OFF (high quality)
}

-- Track original GUI states (to restore correctly)
local originalGUIStates = {}

-- Check if mobile
local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- ============================================================================
-- CREATE SETTINGS GUI
-- ============================================================================
local function createSettingsGUI()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SettingsGUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 150
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	-- Background overlay (semi-transparent black, clickable to close)
	local overlay = Instance.new("TextButton")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.3
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Text = ""
	overlay.AutoButtonColor = false
	overlay.Parent = screenGui

	-- Main Frame (responsive)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"

	-- Responsive sizing (increased height for 4 toggles)
	if isMobile() then
		mainFrame.Size = UDim2.new(0.9, 0, 0.7, 0) -- Mobile: 90% width, 70% height
	else
		mainFrame.Size = UDim2.new(0, 400, 0, 410) -- PC: Fixed 400x410 (taller for 4 toggles)
	end

	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	mainFrame.BackgroundTransparency = 0.1
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = 2
	mainFrame.Parent = screenGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = mainFrame

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	header.BackgroundTransparency = 0.2
	header.BorderSizePixel = 0
	header.ZIndex = 3
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	-- Header Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -60, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Settings"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextStrokeTransparency = 0.5
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 4
	title.Parent = header

	-- Close Button
	local closeButton = Instance.new("ImageButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -40, 0.5, 0)
	closeButton.AnchorPoint = Vector2.new(0, 0.5)
	closeButton.BackgroundTransparency = 1
	closeButton.Image = "rbxassetid://98778427242117" -- X icon
	closeButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.ZIndex = 4
	closeButton.Parent = header

	-- Content Container (ScrollingFrame for mobile scroll support)
	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 1, -80) -- Leave space for header
	content.Position = UDim2.new(0, 10, 0, 70)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 6
	content.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
	content.ScrollBarImageTransparency = 0.5
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y -- Auto-resize canvas
	content.ZIndex = 3
	content.Parent = mainFrame

	-- Content Layout
	local contentLayout = Instance.new("UIListLayout")
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Padding = UDim.new(0, 15)
	contentLayout.Parent = content

	-- Content Padding (for spacing inside scroll)
	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingLeft = UDim.new(0, 10)
	contentPadding.PaddingRight = UDim.new(0, 10)
	contentPadding.PaddingTop = UDim.new(0, 10)
	contentPadding.PaddingBottom = UDim.new(0, 10)
	contentPadding.Parent = content

	-- ========================================================================
	-- TOGGLE 1: Hide/Show Title
	-- ========================================================================
	local titleToggleFrame = Instance.new("Frame")
	titleToggleFrame.Name = "TitleToggle"
	titleToggleFrame.Size = UDim2.new(1, 0, 0, 50)
	titleToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	titleToggleFrame.BackgroundTransparency = 0.3
	titleToggleFrame.BorderSizePixel = 0
	titleToggleFrame.ZIndex = 4
	titleToggleFrame.LayoutOrder = 1
	titleToggleFrame.Parent = content

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = titleToggleFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -70, 1, 0)
	titleLabel.Position = UDim2.new(0, 15, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Show Player Titles"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.Gotham
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 5
	titleLabel.Parent = titleToggleFrame

	local titleToggleButton = Instance.new("TextButton")
	titleToggleButton.Name = "ToggleButton"
	titleToggleButton.Size = UDim2.new(0, 50, 0, 25)
	titleToggleButton.Position = UDim2.new(1, -60, 0.5, 0)
	titleToggleButton.AnchorPoint = Vector2.new(0, 0.5)
	titleToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0) -- Green = ON
	titleToggleButton.BorderSizePixel = 0
	titleToggleButton.Text = ""
	titleToggleButton.ZIndex = 5
	titleToggleButton.Parent = titleToggleFrame

	local titleToggleCorner = Instance.new("UICorner")
	titleToggleCorner.CornerRadius = UDim.new(1, 0)
	titleToggleCorner.Parent = titleToggleButton

	local titleToggleKnob = Instance.new("Frame")
	titleToggleKnob.Name = "Knob"
	titleToggleKnob.Size = UDim2.new(0, 20, 0, 20)
	titleToggleKnob.Position = UDim2.new(1, -22, 0.5, 0) -- Right side (ON)
	titleToggleKnob.AnchorPoint = Vector2.new(0, 0.5)
	titleToggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	titleToggleKnob.BorderSizePixel = 0
	titleToggleKnob.ZIndex = 6
	titleToggleKnob.Parent = titleToggleButton

	local titleKnobCorner = Instance.new("UICorner")
	titleKnobCorner.CornerRadius = UDim.new(1, 0)
	titleKnobCorner.Parent = titleToggleKnob

	-- ========================================================================
	-- TOGGLE 2: Hide/Show GUI
	-- ========================================================================
	local guiToggleFrame = Instance.new("Frame")
	guiToggleFrame.Name = "GUIToggle"
	guiToggleFrame.Size = UDim2.new(1, 0, 0, 50)
	guiToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	guiToggleFrame.BackgroundTransparency = 0.3
	guiToggleFrame.BorderSizePixel = 0
	guiToggleFrame.ZIndex = 4
	guiToggleFrame.LayoutOrder = 2
	guiToggleFrame.Parent = content

	local guiCorner = Instance.new("UICorner")
	guiCorner.CornerRadius = UDim.new(0, 8)
	guiCorner.Parent = guiToggleFrame

	local guiLabel = Instance.new("TextLabel")
	guiLabel.Size = UDim2.new(1, -70, 1, 0)
	guiLabel.Position = UDim2.new(0, 15, 0, 0)
	guiLabel.BackgroundTransparency = 1
	guiLabel.Text = "Show UI Elements"
	guiLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	guiLabel.Font = Enum.Font.Gotham
	guiLabel.TextSize = 14
	guiLabel.TextXAlignment = Enum.TextXAlignment.Left
	guiLabel.ZIndex = 5
	guiLabel.Parent = guiToggleFrame

	local guiToggleButton = Instance.new("TextButton")
	guiToggleButton.Name = "ToggleButton"
	guiToggleButton.Size = UDim2.new(0, 50, 0, 25)
	guiToggleButton.Position = UDim2.new(1, -60, 0.5, 0)
	guiToggleButton.AnchorPoint = Vector2.new(0, 0.5)
	guiToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0) -- Green = ON
	guiToggleButton.BorderSizePixel = 0
	guiToggleButton.Text = ""
	guiToggleButton.ZIndex = 5
	guiToggleButton.Parent = guiToggleFrame

	local guiToggleCorner = Instance.new("UICorner")
	guiToggleCorner.CornerRadius = UDim.new(1, 0)
	guiToggleCorner.Parent = guiToggleButton

	local guiToggleKnob = Instance.new("Frame")
	guiToggleKnob.Name = "Knob"
	guiToggleKnob.Size = UDim2.new(0, 20, 0, 20)
	guiToggleKnob.Position = UDim2.new(1, -22, 0.5, 0) -- Right side (ON)
	guiToggleKnob.AnchorPoint = Vector2.new(0, 0.5)
	guiToggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	guiToggleKnob.BorderSizePixel = 0
	guiToggleKnob.ZIndex = 6
	guiToggleKnob.Parent = guiToggleButton

	local guiKnobCorner = Instance.new("UICorner")
	guiKnobCorner.CornerRadius = UDim.new(1, 0)
	guiKnobCorner.Parent = guiToggleKnob

	-- ========================================================================
	-- TOGGLE 3: Hide/Show Other Players
	-- ========================================================================
	local playersToggleFrame = Instance.new("Frame")
	playersToggleFrame.Name = "PlayersToggle"
	playersToggleFrame.Size = UDim2.new(1, 0, 0, 50)
	playersToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	playersToggleFrame.BackgroundTransparency = 0.3
	playersToggleFrame.BorderSizePixel = 0
	playersToggleFrame.ZIndex = 4
	playersToggleFrame.LayoutOrder = 3
	playersToggleFrame.Parent = content

	local playersCorner = Instance.new("UICorner")
	playersCorner.CornerRadius = UDim.new(0, 8)
	playersCorner.Parent = playersToggleFrame

	local playersLabel = Instance.new("TextLabel")
	playersLabel.Size = UDim2.new(1, -70, 1, 0)
	playersLabel.Position = UDim2.new(0, 15, 0, 0)
	playersLabel.BackgroundTransparency = 1
	playersLabel.Text = "Show Other Players"
	playersLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	playersLabel.Font = Enum.Font.Gotham
	playersLabel.TextSize = 14
	playersLabel.TextXAlignment = Enum.TextXAlignment.Left
	playersLabel.ZIndex = 5
	playersLabel.Parent = playersToggleFrame

	local playersToggleButton = Instance.new("TextButton")
	playersToggleButton.Name = "ToggleButton"
	playersToggleButton.Size = UDim2.new(0, 50, 0, 25)
	playersToggleButton.Position = UDim2.new(1, -60, 0.5, 0)
	playersToggleButton.AnchorPoint = Vector2.new(0, 0.5)
	playersToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0) -- Green = ON
	playersToggleButton.BorderSizePixel = 0
	playersToggleButton.Text = ""
	playersToggleButton.ZIndex = 5
	playersToggleButton.Parent = playersToggleFrame

	local playersToggleCorner = Instance.new("UICorner")
	playersToggleCorner.CornerRadius = UDim.new(1, 0)
	playersToggleCorner.Parent = playersToggleButton

	local playersToggleKnob = Instance.new("Frame")
	playersToggleKnob.Name = "Knob"
	playersToggleKnob.Size = UDim2.new(0, 20, 0, 20)
	playersToggleKnob.Position = UDim2.new(1, -22, 0.5, 0) -- Right side (ON)
	playersToggleKnob.AnchorPoint = Vector2.new(0, 0.5)
	playersToggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	playersToggleKnob.BorderSizePixel = 0
	playersToggleKnob.ZIndex = 6
	playersToggleKnob.Parent = playersToggleButton

	local playersKnobCorner = Instance.new("UICorner")
	playersKnobCorner.CornerRadius = UDim.new(1, 0)
	playersKnobCorner.Parent = playersToggleKnob

	-- ========================================================================
	-- TOGGLE 4: Low Graphics Mode (Performance Optimization)
	-- ========================================================================
	local lowGraphicsToggleFrame = Instance.new("Frame")
	lowGraphicsToggleFrame.Name = "LowGraphicsToggle"
	lowGraphicsToggleFrame.Size = UDim2.new(1, 0, 0, 50)
	lowGraphicsToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	lowGraphicsToggleFrame.BackgroundTransparency = 0.3
	lowGraphicsToggleFrame.BorderSizePixel = 0
	lowGraphicsToggleFrame.ZIndex = 4
	lowGraphicsToggleFrame.LayoutOrder = 4
	lowGraphicsToggleFrame.Parent = content

	local lowGraphicsCorner = Instance.new("UICorner")
	lowGraphicsCorner.CornerRadius = UDim.new(0, 8)
	lowGraphicsCorner.Parent = lowGraphicsToggleFrame

	local lowGraphicsLabel = Instance.new("TextLabel")
	lowGraphicsLabel.Size = UDim2.new(1, -70, 1, 0)
	lowGraphicsLabel.Position = UDim2.new(0, 15, 0, 0)
	lowGraphicsLabel.BackgroundTransparency = 1
	lowGraphicsLabel.Text = "Low Graphics Mode"
	lowGraphicsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	lowGraphicsLabel.Font = Enum.Font.Gotham
	lowGraphicsLabel.TextSize = 14
	lowGraphicsLabel.TextXAlignment = Enum.TextXAlignment.Left
	lowGraphicsLabel.ZIndex = 5
	lowGraphicsLabel.Parent = lowGraphicsToggleFrame

	local lowGraphicsToggleButton = Instance.new("TextButton")
	lowGraphicsToggleButton.Name = "ToggleButton"
	lowGraphicsToggleButton.Size = UDim2.new(0, 50, 0, 25)
	lowGraphicsToggleButton.Position = UDim2.new(1, -60, 0.5, 0)
	lowGraphicsToggleButton.AnchorPoint = Vector2.new(0, 0.5)
	lowGraphicsToggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80) -- Gray = OFF (default)
	lowGraphicsToggleButton.BorderSizePixel = 0
	lowGraphicsToggleButton.Text = ""
	lowGraphicsToggleButton.ZIndex = 5
	lowGraphicsToggleButton.Parent = lowGraphicsToggleFrame

	local lowGraphicsToggleCorner = Instance.new("UICorner")
	lowGraphicsToggleCorner.CornerRadius = UDim.new(1, 0)
	lowGraphicsToggleCorner.Parent = lowGraphicsToggleButton

	local lowGraphicsToggleKnob = Instance.new("Frame")
	lowGraphicsToggleKnob.Name = "Knob"
	lowGraphicsToggleKnob.Size = UDim2.new(0, 20, 0, 20)
	lowGraphicsToggleKnob.Position = UDim2.new(0, 2, 0.5, 0) -- Left side (OFF)
	lowGraphicsToggleKnob.AnchorPoint = Vector2.new(0, 0.5)
	lowGraphicsToggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	lowGraphicsToggleKnob.BorderSizePixel = 0
	lowGraphicsToggleKnob.ZIndex = 6
	lowGraphicsToggleKnob.Parent = lowGraphicsToggleButton

	local lowGraphicsKnobCorner = Instance.new("UICorner")
	lowGraphicsKnobCorner.CornerRadius = UDim.new(1, 0)
	lowGraphicsKnobCorner.Parent = lowGraphicsToggleKnob

	return {
		screenGui = screenGui,
		overlay = overlay,
		mainFrame = mainFrame,
		closeButton = closeButton,
		titleToggleButton = titleToggleButton,
		titleToggleKnob = titleToggleKnob,
		guiToggleButton = guiToggleButton,
		guiToggleKnob = guiToggleKnob,
		playersToggleButton = playersToggleButton,
		playersToggleKnob = playersToggleKnob,
		lowGraphicsToggleButton = lowGraphicsToggleButton,
		lowGraphicsToggleKnob = lowGraphicsToggleKnob,
	}
end

-- ============================================================================
-- TOGGLE FUNCTIONS
-- ============================================================================

-- Update toggle visual state
local function updateToggleVisual(button, knob, isOn)
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	if isOn then
		-- ON state: Green background, knob on right
		TweenService:Create(button, tweenInfo, { BackgroundColor3 = Color3.fromRGB(0, 170, 0) }):Play()
		TweenService:Create(knob, tweenInfo, { Position = UDim2.new(1, -22, 0.5, 0) }):Play()
	else
		-- OFF state: Gray background, knob on left
		TweenService:Create(button, tweenInfo, { BackgroundColor3 = Color3.fromRGB(80, 80, 80) }):Play()
		TweenService:Create(knob, tweenInfo, { Position = UDim2.new(0, 2, 0.5, 0) }):Play()
	end
end

-- Toggle title visibility
local function toggleTitleVisibility()
	settingsState.titlesVisible = not settingsState.titlesVisible

	-- Update all player titles
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		if char then
			local head = char:FindFirstChild("Head")
			if head then
				local mainDisplay = head:FindFirstChild("MainDisplay")
				if mainDisplay and mainDisplay:IsA("BillboardGui") then
					mainDisplay.Enabled = settingsState.titlesVisible
				end
			end
		end
	end
end

-- Toggle GUI visibility
local function toggleGUIVisibility()
	settingsState.guiVisible = not settingsState.guiVisible

	-- List of GUIs to NEVER hide (so player can toggle back)
	local protectedGUINames = {
		"SettingsGUI", -- Settings menu stays visible
	}

	-- Hide/Show all GUIs except protected ones
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			local isProtected = false

			-- Protection 1: Check by name (SettingsGUI popup)
			for _, protectedName in ipairs(protectedGUINames) do
				if gui.Name == protectedName then
					isProtected = true
					break
				end
			end

			-- Protection 2: TopbarPlus icon containers (name starts with "Topbar")
			-- These are the actual button holders, NOT popups!
			if not isProtected and gui.Name:match("^Topbar") then
				isProtected = true
				-- Force TopbarPlus icon containers to always be visible
				gui.Enabled = true
				print("[Settings] Protected TopbarPlus container:", gui.Name)
			end

			-- Protection 3: Check for TopbarPlus structure (IconContainer/Icon descendants)
			if not isProtected then
				for _, descendant in ipairs(gui:GetDescendants()) do
					-- TopbarPlus creates specific structure with these names
					if
						descendant.Name == "IconContainer"
						or descendant.Name == "IconButton"
						or (descendant:IsA("ImageButton") and descendant.Parent and descendant.Parent.Name == "Icon")
					then
						isProtected = true
						-- Force TopbarPlus to always be visible
						gui.Enabled = true
						print("[Settings] Protected by TopbarPlus structure:", gui.Name)
						break
					end
				end
			end

			-- Only toggle non-protected GUIs
			if not isProtected then
				if settingsState.guiVisible then
					-- SHOWING: Restore original state
					if originalGUIStates[gui] ~= nil then
						gui.Enabled = originalGUIStates[gui]
					else
						-- First time, keep current state
						gui.Enabled = gui.Enabled
					end
				else
					-- HIDING: Save current state before hiding
					originalGUIStates[gui] = gui.Enabled
					gui.Enabled = false
				end
			end
		end
	end
end

-- Toggle other players visibility (client-side only)
local function togglePlayersVisibility()
	settingsState.playersVisible = not settingsState.playersVisible

	-- Hide/Show all players EXCEPT local player
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then -- Don't hide local player!
			local char = otherPlayer.Character
			if char then
				-- Set LocalTransparencyModifier for all BaseParts
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						if settingsState.playersVisible then
							-- Show: Set LocalTransparencyModifier to 0
							part.LocalTransparencyModifier = 0
						else
							-- Hide: Set LocalTransparencyModifier to 1
							part.LocalTransparencyModifier = 1
						end
					end
				end
			end
		end
	end
end

-- Helper function: Check if instance is inside Checkpoint folder
local function isInsideCheckpointFolder(instance)
	local current = instance
	while current and current ~= game do
		-- Check if we're inside "cp" folder in Workspace
		if current.Name == "cp" and current.Parent == workspace then
			return true
		end
		current = current.Parent
	end
	return false
end

-- Toggle Low Graphics Mode (Performance Optimization)
local function toggleLowGraphicsMode()
	settingsState.lowGraphicsMode = not settingsState.lowGraphicsMode

	local Lighting = game:GetService("Lighting")
	local Workspace = game:GetService("Workspace")

	if settingsState.lowGraphicsMode then
		-- ========================================================================
		-- LOW GRAPHICS MODE: ON (Performance Mode)
		-- ========================================================================

		-- 1. Disable Global Shadows
		Lighting.GlobalShadows = false

		-- 2. Disable CastShadow on all Parts in Workspace (SKIP Checkpoint folder)
		for _, descendant in ipairs(Workspace:GetDescendants()) do
			if descendant:IsA("BasePart") then
				-- Skip checkpoint folder parts (they may need shadows for visibility)
				if not isInsideCheckpointFolder(descendant) then
					descendant.CastShadow = false
				end
			end
		end

		-- 3. Disable Particle Effects (SKIP Checkpoint folder - keep aura markers)
		for _, descendant in ipairs(Workspace:GetDescendants()) do
			-- CRITICAL: Skip checkpoint folder effects (visual markers for gameplay)
			if isInsideCheckpointFolder(descendant) then
				continue -- Keep checkpoint auras enabled
			end

			if descendant:IsA("ParticleEmitter") then
				descendant.Enabled = false
			elseif descendant:IsA("Beam") then
				descendant.Enabled = false
			elseif descendant:IsA("Trail") then
				descendant.Enabled = false
			end
		end

		-- 4. Disable Post-Processing Effects in Lighting
		for _, effect in ipairs(Lighting:GetChildren()) do
			if
				effect:IsA("BlurEffect")
				or effect:IsA("BloomEffect")
				or effect:IsA("SunRaysEffect")
				or effect:IsA("ColorCorrectionEffect")
				or effect:IsA("DepthOfFieldEffect")
			then
				effect.Enabled = false
			end
		end

		-- 5. Disable effects in Camera (if any)
		local camera = workspace.CurrentCamera
		if camera then
			for _, effect in ipairs(camera:GetChildren()) do
				if
					effect:IsA("BlurEffect")
					or effect:IsA("BloomEffect")
					or effect:IsA("SunRaysEffect")
					or effect:IsA("ColorCorrectionEffect")
					or effect:IsA("DepthOfFieldEffect")
				then
					effect.Enabled = false
				end
			end
		end

		print("[Settings] ⚡ Low Graphics Mode: ENABLED (Performance optimized, checkpoint auras preserved)")
	else
		-- ========================================================================
		-- LOW GRAPHICS MODE: OFF (High Quality)
		-- ========================================================================

		-- 1. Enable Global Shadows
		Lighting.GlobalShadows = true

		-- 2. Enable CastShadow on all Parts in Workspace
		for _, descendant in ipairs(Workspace:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.CastShadow = true
			end
		end

		-- 3. Enable Particle Effects (checkpoint effects already enabled, safe to enable all)
		for _, descendant in ipairs(Workspace:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") then
				descendant.Enabled = true
			elseif descendant:IsA("Beam") then
				descendant.Enabled = true
			elseif descendant:IsA("Trail") then
				descendant.Enabled = true
			end
		end

		-- 4. Enable Post-Processing Effects in Lighting
		for _, effect in ipairs(Lighting:GetChildren()) do
			if
				effect:IsA("BlurEffect")
				or effect:IsA("BloomEffect")
				or effect:IsA("SunRaysEffect")
				or effect:IsA("ColorCorrectionEffect")
				or effect:IsA("DepthOfFieldEffect")
			then
				effect.Enabled = true
			end
		end

		-- 5. Enable effects in Camera (if any)
		local camera = workspace.CurrentCamera
		if camera then
			for _, effect in ipairs(camera:GetChildren()) do
				if
					effect:IsA("BlurEffect")
					or effect:IsA("BloomEffect")
					or effect:IsA("SunRaysEffect")
					or effect:IsA("ColorCorrectionEffect")
					or effect:IsA("DepthOfFieldEffect")
				then
					effect.Enabled = true
				end
			end
		end

		print("[Settings] ✨ Low Graphics Mode: DISABLED (High quality restored)")
	end
end

-- Setup player visibility tracking for new players
local function setupPlayerVisibilityTracking()
	-- Apply to all existing players
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local function onCharacterAdded(char)
				-- Wait a bit for character to fully load
				task.wait(0.1)

				-- Apply current visibility setting
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.LocalTransparencyModifier = settingsState.playersVisible and 0 or 1
					end
				end
			end

			-- Connect to current character
			if otherPlayer.Character then
				onCharacterAdded(otherPlayer.Character)
			end

			-- Connect to future characters (respawn)
			otherPlayer.CharacterAdded:Connect(onCharacterAdded)
		end
	end

	-- Connect to new players joining
	Players.PlayerAdded:Connect(function(newPlayer)
		if newPlayer ~= player then
			newPlayer.CharacterAdded:Connect(function(char)
				task.wait(0.1)
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.LocalTransparencyModifier = settingsState.playersVisible and 0 or 1
					end
				end
			end)
		end
	end)
end

-- ============================================================================
-- SHOW/HIDE SETTINGS
-- ============================================================================
local function showSettings()
	if isVisible then
		return
	end

	if not settingsGui then
		settingsGui = createSettingsGUI()

		-- Setup toggle button handlers
		settingsGui.titleToggleButton.MouseButton1Click:Connect(function()
			toggleTitleVisibility()
			updateToggleVisual(settingsGui.titleToggleButton, settingsGui.titleToggleKnob, settingsState.titlesVisible)
		end)

		settingsGui.guiToggleButton.MouseButton1Click:Connect(function()
			toggleGUIVisibility()
			updateToggleVisual(settingsGui.guiToggleButton, settingsGui.guiToggleKnob, settingsState.guiVisible)
		end)

		settingsGui.playersToggleButton.MouseButton1Click:Connect(function()
			togglePlayersVisibility()
			updateToggleVisual(
				settingsGui.playersToggleButton,
				settingsGui.playersToggleKnob,
				settingsState.playersVisible
			)
		end)

		settingsGui.lowGraphicsToggleButton.MouseButton1Click:Connect(function()
			toggleLowGraphicsMode()
			updateToggleVisual(
				settingsGui.lowGraphicsToggleButton,
				settingsGui.lowGraphicsToggleKnob,
				settingsState.lowGraphicsMode
			)
		end)

		-- Close button
		settingsGui.closeButton.MouseButton1Click:Connect(function()
			hideSettings()
		end)

		-- Click overlay to close
		settingsGui.overlay.MouseButton1Click:Connect(function()
			hideSettings()
		end)

		-- Initialize toggle visuals
		updateToggleVisual(settingsGui.titleToggleButton, settingsGui.titleToggleKnob, settingsState.titlesVisible)
		updateToggleVisual(settingsGui.guiToggleButton, settingsGui.guiToggleKnob, settingsState.guiVisible)
		updateToggleVisual(settingsGui.playersToggleButton, settingsGui.playersToggleKnob, settingsState.playersVisible)
		updateToggleVisual(
			settingsGui.lowGraphicsToggleButton,
			settingsGui.lowGraphicsToggleKnob,
			settingsState.lowGraphicsMode
		)
	end

	settingsGui.screenGui.Enabled = true
	isVisible = true

	-- Fade in animation
	local overlay = settingsGui.overlay
	local mainFrame = settingsGui.mainFrame

	overlay.BackgroundTransparency = 1
	mainFrame.BackgroundTransparency = 1
	mainFrame.Position = UDim2.new(0.5, 0, 0.55, 0)

	-- Set correct size based on mobile/PC (updated for 4 toggles)
	local targetSize = isMobile() and UDim2.new(0.9, 0, 0.7, 0) or UDim2.new(0, 400, 0, 410)
	mainFrame.Size = targetSize

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	TweenService:Create(overlay, tweenInfo, { BackgroundTransparency = 0.3 }):Play()
	TweenService:Create(mainFrame, tweenInfo, {
		BackgroundTransparency = 0.1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()
end

function hideSettings()
	if not isVisible or not settingsGui then
		return
	end

	local overlay = settingsGui.overlay
	local mainFrame = settingsGui.mainFrame

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	local overlayTween = TweenService:Create(overlay, tweenInfo, { BackgroundTransparency = 1 })
	local frameTween = TweenService:Create(mainFrame, tweenInfo, {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.55, 0),
	})

	overlayTween:Play()
	frameTween:Play()

	frameTween.Completed:Connect(function()
		settingsGui.screenGui.Enabled = false
		isVisible = false
	end)
end

-- ============================================================================
-- CREATE TOPBARPLUS ICON
-- ============================================================================
local function createTopbarIcon()
	local settingsIcon = Icon.new()
	settingsIcon:setName("Settings")
	settingsIcon:setLabel("Settings") -- Add text label beside icon
	settingsIcon:setImage(SETTINGS_ICONS.Deselected, "Deselected")
	settingsIcon:setImage(SETTINGS_ICONS.Selected, "Selected")

	-- Toggle settings on click
	settingsIcon.selected:Connect(function()
		showSettings()
	end)

	settingsIcon.deselected:Connect(function()
		hideSettings()
	end)

	return settingsIcon
end

-- ============================================================================
-- INITIALIZE
-- ============================================================================
task.wait(1) -- Wait for TopbarPlus to be ready
local settingsIcon = createTopbarIcon()

-- Setup player visibility tracking (for new players/respawns)
setupPlayerVisibilityTracking()

print("✅ [Settings] Settings system loaded!")
