-- ========================================
-- COLLISION GROUP SETUP FOR CARRY SYSTEM
-- ========================================
-- Sistem ini membuat player yang di-carry menjadi "ghost"
-- yang tembus obstacle tapi tetap kena checkpoint & summit

local PhysicsService = game:GetService("PhysicsService")
local Workspace = game:GetService("Workspace")

-- ========================================
-- COLLISION GROUP NAMES
-- ========================================
local COLLISION_GROUPS = {
	DEFAULT = "Default",
	PLAYERS = "Players", -- All players (tembus satu sama lain)
	CARRIED_PLAYER = "CarriedPlayer", -- Currently carried (ghost through world)
	CHECKPOINTS = "Checkpoints",
}

-- ========================================
-- CREATE COLLISION GROUPS
-- ========================================
local function setupCollisionGroups()
	-- Create Players collision group
	pcall(function()
		PhysicsService:CreateCollisionGroup(COLLISION_GROUPS.PLAYERS)
	end)

	-- Create CarriedPlayer collision group
	pcall(function()
		PhysicsService:CreateCollisionGroup(COLLISION_GROUPS.CARRIED_PLAYER)
	end)

	-- Create Checkpoints collision group
	pcall(function()
		PhysicsService:CreateCollisionGroup(COLLISION_GROUPS.CHECKPOINTS)
	end)

	-- ========================================
	-- COLLISION RULES
	-- ========================================

	-- Players CANNOT collide with other Players (tembus satu sama lain)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(
			COLLISION_GROUPS.PLAYERS,
			COLLISION_GROUPS.PLAYERS,
			false
		)
	end)

	-- Players CAN collide with Default (world/obstacles)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(
			COLLISION_GROUPS.PLAYERS,
			COLLISION_GROUPS.DEFAULT,
			true
		)
	end)

	-- Players CAN collide with Checkpoints
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(
			COLLISION_GROUPS.PLAYERS,
			COLLISION_GROUPS.CHECKPOINTS,
			true
		)
	end)

	-- CarriedPlayer CANNOT collide with Default (world/obstacles - ghost)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(
			COLLISION_GROUPS.CARRIED_PLAYER,
			COLLISION_GROUPS.DEFAULT,
			false
		)
	end)

	-- CarriedPlayer CAN collide with Checkpoints (CP, Summit, FallArea)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(
			COLLISION_GROUPS.CARRIED_PLAYER,
			COLLISION_GROUPS.CHECKPOINTS,
			true
		)
	end)

	-- CarriedPlayer CANNOT collide with Players
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(
			COLLISION_GROUPS.CARRIED_PLAYER,
			COLLISION_GROUPS.PLAYERS,
			false
		)
	end)

	-- CarriedPlayer CANNOT collide with other CarriedPlayers
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(
			COLLISION_GROUPS.CARRIED_PLAYER,
			COLLISION_GROUPS.CARRIED_PLAYER,
			false
		)
	end)

	print("✅ Collision groups setup complete!")
end

-- ========================================
-- ASSIGN CHECKPOINT PARTS TO GROUP
-- ========================================
local function assignPartToCheckpointGroup(part)
	if part:IsA("BasePart") then
		pcall(function()
			PhysicsService:SetPartCollisionGroup(part, COLLISION_GROUPS.CHECKPOINTS)
		end)
	end
end

local function setupCheckpointParts()
	local checkpointFolder = Workspace:FindFirstChild("cp")
	if not checkpointFolder then
		warn("⚠️ Checkpoint folder not found!")
		return
	end

	-- Loop through all checkpoint folders
	for _, cpFolder in ipairs(checkpointFolder:GetChildren()) do
		if cpFolder:IsA("Folder") or cpFolder:IsA("Model") then
			-- Find checkpoint parts (CP1, CP2, etc.)
			for _, part in ipairs(cpFolder:GetDescendants()) do
				if part:IsA("BasePart") then
					local partName = part.Name

					-- Assign to Checkpoints group if:
					-- 1. Part is named "CP1", "CP2", etc. (checkpoint trigger)
					-- 2. Part is named "CPFallArea" (fall detection)
					-- 3. Part is named "AreaCP" (alternative checkpoint name)
					-- 4. Part is named "AreaBawahAuraCP" (checkpoint area)
					if partName:match("^CP%d+$")
						or partName == "CPFallArea"
						or partName == "AreaCP"
						or partName == "AreaBawahAuraCP" then
						assignPartToCheckpointGroup(part)
					end
				end
			end
		end
	end

	-- Assign Summit Part
	local summitPart = checkpointFolder:FindFirstChild("SummitPlate")
		or Workspace:FindFirstChild("SummitPlate")

	if summitPart then
		assignPartToCheckpointGroup(summitPart)
		print("✅ Summit part assigned to Checkpoints group")
	else
		warn("⚠️ Summit part not found!")
	end

	print("✅ Checkpoint parts setup complete!")
end

-- ========================================
-- LISTEN FOR NEW CHECKPOINT PARTS
-- ========================================
local function monitorNewCheckpointParts()
	local checkpointFolder = Workspace:FindFirstChild("cp")
	if not checkpointFolder then
		return
	end

	-- Listen for new folders being added
	checkpointFolder.DescendantAdded:Connect(function(descendant)
		task.wait(0.1) -- Wait for part to fully load

		if descendant:IsA("BasePart") then
			local partName = descendant.Name

			if partName:match("^CP%d+$")
				or partName == "CPFallArea"
				or partName == "AreaCP"
				or partName == "AreaBawahAuraCP"
				or partName == "SummitPlate" then
				assignPartToCheckpointGroup(descendant)
			end
		end
	end)
end

-- ========================================
-- SET PLAYERS TO "Players" COLLISION GROUP
-- ========================================
local Players = game:GetService("Players")

local function setPlayerCollisionGroup(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.1) -- Wait for character to fully load

		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				pcall(function()
					PhysicsService:SetPartCollisionGroup(part, COLLISION_GROUPS.PLAYERS)
				end)
			end
		end

		-- Monitor for new parts added to character
		character.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("BasePart") then
				task.wait(0.05)
				pcall(function()
					PhysicsService:SetPartCollisionGroup(descendant, COLLISION_GROUPS.PLAYERS)
				end)
			end
		end)
	end)

	-- Handle if player already has character
	if player.Character then
		for _, part in ipairs(player.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				pcall(function()
					PhysicsService:SetPartCollisionGroup(part, COLLISION_GROUPS.PLAYERS)
				end)
			end
		end
	end
end

-- Set collision group for all current players
for _, player in ipairs(Players:GetPlayers()) do
	setPlayerCollisionGroup(player)
end

-- Set collision group for future players
Players.PlayerAdded:Connect(setPlayerCollisionGroup)

-- ========================================
-- INITIALIZE
-- ========================================
setupCollisionGroups()
task.wait(0.5) -- Wait for collision groups to register
setupCheckpointParts()
monitorNewCheckpointParts()

-- Expose to global for CarryWeld to use
_G.CarryCollisionGroups = COLLISION_GROUPS

print("🚀 Carry Collision System loaded!")
