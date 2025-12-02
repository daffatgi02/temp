-- ServerScriptService -> SummitPanelServer (WITH SET SUMMIT)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RequestRemote = ReplicatedStorage:WaitForChild("SummitAdminPanel_Request")
local GetDataRemote = ReplicatedStorage:WaitForChild("SummitAdminPanel_GetData")

local authorizedUsers = {}

_G.SummitPanel_AuthorizeUser = function(player)
	if player and player:IsA("Player") then
		authorizedUsers[player.UserId] = true
	end
end

local function isAdmin(player)
	if authorizedUsers[player.UserId] then
		return true
	end

	if player.UserId == game.CreatorId then
		authorizedUsers[player.UserId] = true
		return true
	end

	local validAdminIds = {
		8978258458,
		9612593502,
	}

	if table.find(validAdminIds, player.UserId) then
		authorizedUsers[player.UserId] = true
		return true
	end

	return false
end

Players.PlayerRemoving:Connect(function(player)
	authorizedUsers[player.UserId] = nil
end)

GetDataRemote.OnServerInvoke = function(player)
	if not isAdmin(player) then
		return { success = false, message = "You don't have permission" }
	end

	if not _G.SummitSystem then
		return { success = false, message = "Summit System not loaded" }
	end

	local playerData = {}

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		local currentCP = _G.SummitSystem.GetCheckpoint(targetPlayer) or "Spawn"
		local summits = _G.SummitSystem.GetSummits(targetPlayer) or 0

		table.insert(playerData, {
			Name = targetPlayer.Name,
			DisplayName = targetPlayer.DisplayName,
			UserId = targetPlayer.UserId,
			CurrentCP = currentCP,
			Summits = summits,
		})
	end

	table.sort(playerData, function(a, b)
		return a.Name < b.Name
	end)

	return {
		success = true,
		players = playerData,
		checkpoints = _G.SummitSystem.GetCheckpointList(),
	}
end

RequestRemote.OnServerEvent:Connect(function(player, action, targetPlayerName, value)
	if not isAdmin(player) then
		return
	end

	if not _G.SummitSystem then
		return
	end

	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then
		return
	end

	-- SET CHECKPOINT (includes teleport)
	if action == "SetCheckpoint" then
		pcall(function()
			_G.SummitSystem.SetCheckpoint(targetPlayer, value)
			_G.SummitSystem.TeleportToCheckpoint(targetPlayer, value)
		end)

		-- 🔥 NEW: SET SUMMIT
	elseif action == "SetSummit" then
		local amount = tonumber(value)

		-- Validation
		if not amount then
			return
		end

		amount = math.floor(amount)

		if amount < 0 or amount > 100000 then
			return
		end

		pcall(function()
			_G.SummitSystem.SetSummits(targetPlayer, amount)
		end)
	end
end)

print("✅ Summit Admin Panel init")
