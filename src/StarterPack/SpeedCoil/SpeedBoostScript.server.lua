-- ============================================================================
-- SpeedBoostScript - WalkSpeed 35, SwimmingSpeed Configurable
-- ============================================================================
-- WalkSpeed: 16 (no item) → 35 (equipped) - TIDAK DIUBAH
-- SwimmingSpeed: Configurable di Config (default 25)

local sp = script.Parent
local smokepart = nil

-- Get references
local tooltag = script:WaitForChild("ToolTag", 2)
local selectedSpeedValue = script:WaitForChild("SelectedSpeed", 2)

if not tooltag or not selectedSpeedValue then
	script:Destroy()
	return
end

local tool = tooltag.Value
if not tool then
	script:Destroy()
	return
end

-- Load Config
local configModule = tool:FindFirstChild("Config")
if not configModule then
	script:Destroy()
	return
end

local Config = require(configModule)
local boostWalkSpeed = selectedSpeedValue.Value

-- Apply to Humanoid
local h = sp:FindFirstChild("Humanoid")
local stateConnection

if h then
	-- Set boost walk speed (35)
	h.WalkSpeed = boostWalkSpeed

	-- Calculate WalkSpeed needed for desired swimming speed
	-- Swimming = WalkSpeed × 0.875, so WalkSpeed = Swimming / 0.875
	local swimmingWalkSpeed = Config.SwimmingSpeed / 0.875

	-- Monitor swimming state to override speed
	stateConnection = h.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Swimming then
			-- Entering water - adjust for swimming speed
			h.WalkSpeed = swimmingWalkSpeed
		elseif oldState == Enum.HumanoidStateType.Swimming then
			-- Leaving water - restore boost walk speed
			h.WalkSpeed = boostWalkSpeed
		end
	end)

	local hrp = sp:FindFirstChild("HumanoidRootPart")

	-- Create smoke effect (optional)
	if hrp and Config.Smoke.enabled then
		smokepart = Instance.new("Part")
		smokepart.FormFactor = "Custom"
		smokepart.Size = Vector3.new(0, 0, 0)
		smokepart.TopSurface = "Smooth"
		smokepart.BottomSurface = "Smooth"
		smokepart.CanCollide = false
		smokepart.Transparency = 1

		local weld = Instance.new("Weld")
		weld.Name = "SmokePartWeld"
		weld.Part0 = hrp
		weld.Part1 = smokepart
		weld.C0 = CFrame.new(0, -3.5, 0) * CFrame.Angles(math.pi / 4, 0, 0)
		weld.Parent = smokepart
		smokepart.Parent = sp

		local smoke = Instance.new("Smoke")
		smoke.Enabled = hrp.Velocity.magnitude > Config.Smoke.minSpeed
		smoke.RiseVelocity = Config.Smoke.riseVelocity
		smoke.Opacity = Config.Smoke.opacity
		smoke.Size = Config.Smoke.size
		smoke.Color = Config.Smoke.color
		smoke.Parent = smokepart

		h.Running:Connect(function(speed)
			if smoke then
				smoke.Enabled = speed > Config.Smoke.minSpeed
			end
		end)
	end
end

-- ============================================================================
-- CLEANUP FUNCTION (Proper reset)
-- ============================================================================
local function cleanup()
	-- Disconnect state monitoring
	if stateConnection then
		stateConnection:Disconnect()
		stateConnection = nil
	end

	-- Reset to base walk speed (16)
	if h and h.Parent then
		h.WalkSpeed = Config.BaseWalkSpeed
	end

	-- Destroy smoke
	if smokepart then
		smokepart:Destroy()
	end

	-- Destroy script
	script:Destroy()
end

-- ============================================================================
-- EVENT-DRIVEN UNEQUIP DETECTION (Fixed!)
-- ============================================================================
-- ✅ Use tool.Unequipped event instead of unreliable ChildRemoved loop
local unequipConnection
if tool then
	unequipConnection = tool.Unequipped:Connect(function()
		--print("[SpeedCoil] Tool unequipped - cleaning up")
		cleanup()
	end)
end

-- Fallback: Also check if tool is removed from character
local toolRemovedConnection
toolRemovedConnection = tool.AncestryChanged:Connect(function()
	if not tool:IsDescendantOf(game) then
		--print("[SpeedCoil] Tool removed - cleaning up")
		cleanup()
	end
end)

-- Fallback: Check if character is destroyed
local characterDestroyingConnection
characterDestroyingConnection = sp.Destroying:Connect(function()
	--print("[SpeedCoil] Character destroyed - cleaning up")
	if unequipConnection then unequipConnection:Disconnect() end
	if toolRemovedConnection then toolRemovedConnection:Disconnect() end
	cleanup()
end)