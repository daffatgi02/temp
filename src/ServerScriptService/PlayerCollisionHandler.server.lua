-- Script untuk membuat semua pemain bisa tembus satu sama lain
-- Berguna untuk obby agar pemain tidak tabrakan saat parkour atau carry

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

-- Nama collision group untuk pemain
local PLAYERS_COLLISION_GROUP = "Players"

-- Setup collision group
local function setupCollisionGroups()
	-- Buat collision group jika belum ada
	if not pcall(function()
		PhysicsService:GetCollisionGroupId(PLAYERS_COLLISION_GROUP)
	end) then
		PhysicsService:CreateCollisionGroup(PLAYERS_COLLISION_GROUP)
	end

	-- Set agar pemain tidak bisa tabrakan dengan pemain lain
	PhysicsService:CollisionGroupSetCollidable(PLAYERS_COLLISION_GROUP, PLAYERS_COLLISION_GROUP, false)

	print("[CollisionHandler] Collision groups setup complete - Players can now pass through each other")
end

-- Set collision group untuk semua parts di character
local function setCharacterCollisionGroup(character)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = PLAYERS_COLLISION_GROUP
		end
	end
end

-- Handler saat player spawn
local function onCharacterAdded(character)
	-- Tunggu character fully loaded
	character:WaitForChild("HumanoidRootPart")

	-- Set collision group untuk semua parts
	setCharacterCollisionGroup(character)

	-- Monitor jika ada parts baru ditambahkan (seperti accessories)
	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = PLAYERS_COLLISION_GROUP
		end
	end)

	print("[CollisionHandler] Set collision group for player:", character.Name)
end

-- Handler saat player join
local function onPlayerAdded(player)
	-- Handle character saat ini jika ada
	if player.Character then
		onCharacterAdded(player.Character)
	end

	-- Handle character yang akan di-spawn
	player.CharacterAdded:Connect(onCharacterAdded)
end

-- Setup
setupCollisionGroups()

-- Handle semua player yang sudah ada
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Handle player baru yang join
Players.PlayerAdded:Connect(onPlayerAdded)

print("[CollisionHandler] Script initialized - All players will pass through each other during parkour and carry")
