local main = _G.HDAdminMain
local settings = main.settings

-- HELPER: Normalisasi player arg menjadi table
local function toTargets(arg, speaker)
	if typeof(arg) == "Instance" and arg:IsA("Player") then
		return {arg}
	elseif type(arg) == "table" then
		return arg
	else
		return {speaker}
	end
end

local module = {
	-- Reset Checkpoint ke Spawn
	{
		Name = "resetcp";
		Aliases = {"rcp", "respawncp"};
		Prefixes = {settings.Prefix, settings.UniversalPrefix};
		Rank = 2;
		RankLock = false;
		Loopable = true;
		Tags = {"Checkpoint", "Moderation"};
		Description = "Reset checkpoint player ke spawn";
		Contributors = {};
		Args = {"player"}; 
		Function = function(speaker, args)
			-- Guard Summit System
			if not _G.SummitSystem or type(_G.SummitSystem.SetCheckpoint) ~= "function" then
				return "Summit System not loaded"
			end

			-- Normalisasi targets
			local targets = toTargets(args[1], speaker)

			local resetCount = 0
			for _, player in pairs(targets) do
				if player and player:IsA("Player") then
					local ok = pcall(function()
						local success = _G.SummitSystem.SetCheckpoint(player, "Spawn")
						if success then
							_G.SummitSystem.TeleportToCheckpoint(player, "Spawn")
							resetCount = resetCount + 1
						end
					end)

					if not ok then
						warn("resetcp error for", player.Name)
					end
				end
			end

			if resetCount == 0 then
				return "Tidak ada player yang direset"
			end

			return string.format("Reset checkpoint %d player ke spawn", resetCount)
		end;
	};
	
	{
		Name = "setsummit";
		Aliases = {"setsum", "forcesummit", "fsum"};
		Prefixes = {settings.Prefix, settings.UniversalPrefix};
		Rank = 2;
		RankLock = false;
		Loopable = true;
		Tags = {"Summit", "Moderation"};
		Description = "Set jumlah summit player (0-100000)";
		Contributors = {};
		Args = {"player", "number"}; 
		Function = function(speaker, args)
			-- Guard Summit System
			if not _G.SummitSystem or type(_G.SummitSystem.SetSummits) ~= "function" then
				return "Summit System not loaded"
			end

			-- Validasi amount
			local amount = tonumber(args[2])
			if not amount then
				return "Input tidak valid! Gunakan angka (0-100000)"
			end

			-- Clamp ke range valid
			amount = math.floor(amount)
			if amount < 0 then
				return "Summit tidak boleh negatif!"
			elseif amount > 100000 then
				return "Maximum summit adalah 100000!"
			end

			-- Normalisasi targets
			local targets = toTargets(args[1], speaker)

			local setCount = 0
			for _, player in pairs(targets) do
				if player and player:IsA("Player") then
					local ok = pcall(function()
						local success = _G.SummitSystem.SetSummits(player, amount)
						if success then
							setCount = setCount + 1
						end
					end)

					if not ok then
						warn("setsummit error for", player.Name)
					end
				end
			end

			if setCount == 0 then
				return "Tidak ada player yang diubah"
			end

			return string.format("Set summit %d player ke %d", setCount, amount)
		end;
	};

	-- RESET SUMMIT COMMAND (Set to 0)
	{
		Name = "resetsummit";
		Aliases = {"rsum", "clearsum"};
		Prefixes = {settings.Prefix, settings.UniversalPrefix};
		Rank = 2;
		RankLock = false;
		Loopable = true;
		Tags = {"Summit", "Moderation"};
		Description = "Reset summit player ke 0";
		Contributors = {};
		Args = {"player"}; 
		Function = function(speaker, args)
			-- Guard Summit System
			if not _G.SummitSystem or type(_G.SummitSystem.SetSummits) ~= "function" then
				return "Summit System not loaded"
			end

			-- Normalisasi targets
			local targets = toTargets(args[1], speaker)

			local resetCount = 0
			for _, player in pairs(targets) do
				if player and player:IsA("Player") then
					local ok = pcall(function()
						local success = _G.SummitSystem.SetSummits(player, 0)
						if success then
							resetCount = resetCount + 1
						end
					end)

					if not ok then
						warn("resetsummit error for", player.Name)
					end
				end
			end

			if resetCount == 0 then
				return "Tidak ada player yang direset"
			end

			return string.format("Reset summit %d player ke 0", resetCount)
		end;
	};

	-- Set Checkpoint ke CP tertentu
	{
		Name = "setcp";
		Aliases = {"scp"};
		Prefixes = {settings.Prefix, settings.UniversalPrefix};
		Rank = 2;
		RankLock = false;
		Loopable = true;
		Tags = {"Checkpoint", "Moderation"};
		Description = "Set checkpoint player ke CP tertentu";
		Contributors = {};
		Args = {"player", "singletext"};  -- FIX: Array of strings langsung!
		Function = function(speaker, args)
			-- Guard Summit System
			if not _G.SummitSystem or type(_G.SummitSystem.SetCheckpoint) ~= "function" then
				return "Summit System not loaded"
			end

			-- Validasi checkpoint arg
			if not args[2] or args[2] == "" then
				return "Masukkan nama checkpoint (Spawn, CP1-CP10)"
			end

			local cpName = args[2]

			-- Validasi checkpoint valid
			local ok, validCheckpoints = pcall(function()
				return _G.SummitSystem.GetCheckpointList()
			end)

			if not ok or not validCheckpoints then
				return "Gagal mengambil daftar checkpoint"
			end

			if not table.find(validCheckpoints, cpName) then
				return "Checkpoint tidak valid! Gunakan: Spawn, CP1-CP10"
			end

			-- Normalisasi targets
			local targets = toTargets(args[1], speaker)

			local setCount = 0
			for _, player in pairs(targets) do
				if player and player:IsA("Player") then
					local ok2 = pcall(function()
						local success = _G.SummitSystem.SetCheckpoint(player, cpName)
						if success then
							_G.SummitSystem.TeleportToCheckpoint(player, cpName)
							setCount = setCount + 1
						end
					end)

					if not ok2 then
						warn("setcp error for", player.Name)
					end
				end
			end

			if setCount == 0 then
				return "Tidak ada player yang diubah"
			end

			return string.format("Set checkpoint %d player ke %s", setCount, cpName)
		end;
	};
	{
		Name = "summitpanel";
		Aliases = {"sumpanel", "sppanel", "cpanel"};
		Prefixes = {settings.Prefix, settings.UniversalPrefix};
		Rank = 2;
		RankLock = false;
		Loopable = false;
		Tags = {"Checkpoint", "Admin", "GUI"};
		Description = "Buka panel admin untuk manage checkpoint player";
		Contributors = {};
		Args = {};
		Function = function(speaker, args)
			if not _G.SummitSystem then
				return "Summit System not loaded"
			end

			-- Authorize user directly (server side)
			if _G.SummitPanel_AuthorizeUser then
				_G.SummitPanel_AuthorizeUser(speaker)
			end

			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local openPanelRemote = ReplicatedStorage:FindFirstChild("OpenSummitPanel")

			if openPanelRemote then
				openPanelRemote:FireClient(speaker)
				return "Opening Summit Panel..."
			else
				return "Panel system not initialized"
			end
		end;
	};

}

return module