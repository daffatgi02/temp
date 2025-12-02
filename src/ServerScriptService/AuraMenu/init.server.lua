-- Aura System Server Script - Full (All-parts support + fixed table.insert error)
-- Place this Script under ServerScriptService
-- Folder structure: thisScript.Auras.<AuraName>.<PartName> (PartName may be Head, LeftHand, LeftUpperArm, UpperTorso, RootPart, etc.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Toggle for debug prints (set true to see detailed warnings)
local DEBUG_AURA = false

-- Admins who bypass summit requirements
local allowedAdmins = {
	[8978258458] = true, -- cho
	[9612593502] = true, -- dapa
}

-- Aura definitions (edit names/requirements/colors as needed)
local AURA_REQUIREMENTS = {
	{ name = "The Beginning", summit = 25, color = Color3.fromRGB(200, 200, 200), emoji = "" },
	{ name = "Eternity", summit = 100, color = Color3.fromRGB(170, 170, 127), emoji = "" },
	{ name = "Void", summit = 250, color = Color3.fromRGB(85, 0, 127), emoji = "" },
	{ name = "Conquest", summit = 500, color = Color3.fromRGB(255, 200, 0), emoji = "" },
	{ name = "Wonders", summit = 1000, color = Color3.fromRGB(85, 0, 0), emoji = "" },
	{ name = "Realities", summit = 1500, color = Color3.fromRGB(255, 100, 255), emoji = "" },
	{ name = "Abyss", summit = 3500, color = Color3.fromRGB(255, 255, 255), emoji = "" },
}

-- Networking: recreate AuraRemotes
local existingAuraRemotes = ReplicatedStorage:FindFirstChild("AuraRemotes")
if existingAuraRemotes then
	existingAuraRemotes:Destroy()
end

local auraRemotes = Instance.new("Folder")
auraRemotes.Name = "AuraRemotes"
auraRemotes.Parent = ReplicatedStorage

local auraSelectionRemote = Instance.new("RemoteEvent")
auraSelectionRemote.Name = "AuraSelection"
auraSelectionRemote.Parent = auraRemotes

local getAurasRemote = Instance.new("RemoteFunction")
getAurasRemote.Name = "GetAvailableAuras"
getAurasRemote.Parent = auraRemotes

local createAuraGUIRemote = Instance.new("RemoteEvent")
createAuraGUIRemote.Name = "CreateAuraGUI"
createAuraGUIRemote.Parent = auraRemotes

-- State tracking
local playerAuraOverrides = {} -- [userId] = auraName
local activeAuras = {} -- [userId] = {Instance, ...}

-- Allowed template names (extended)
local ALLOWED_BODY_PARTS = {
	["Head"] = true,
	["LeftHand"] = true,
	["Left Hand"] = true,
	["RightHand"] = true,
	["Right Hand"] = true,
	["LeftUpperArm"] = true,
	["Left Arm"] = true,
	["LeftArm"] = true,
	["RightUpperArm"] = true,
	["Right Arm"] = true,
	["RightArm"] = true,
	["LeftLowerArm"] = true,
	["RightLowerArm"] = true,
	["LeftUpperLeg"] = true,
	["Left Leg"] = true,
	["LeftLeg"] = true,
	["RightUpperLeg"] = true,
	["Right Leg"] = true,
	["RightLeg"] = true,
	["LeftLowerLeg"] = true,
	["RightLowerLeg"] = true,
	["LeftFoot"] = true,
	["RightFoot"] = true,
	["LowerTorso"] = true,
	["UpperTorso"] = true,
	["Torso"] = true,
	["RootPart"] = true,
	["HumanoidRootPart"] = true,
}

-- Alias mapping from template key -> possible character child names
local PART_NAME_ALIASES = {
	["Head"] = { "Head" },
	["Left Hand"] = { "LeftHand", "Left Hand", "LeftHand", "LeftUpperArm", "LeftArm" },
	["LeftHand"] = { "LeftHand", "LeftUpperArm", "LeftArm" },
	["Right Hand"] = { "RightHand", "Right Hand", "RightHand", "RightUpperArm", "RightArm" },
	["RightHand"] = { "RightHand", "RightUpperArm", "RightArm" },
	["LeftUpperArm"] = { "LeftUpperArm", "LeftArm", "Left Upper Arm", "LeftArm" },
	["RightUpperArm"] = { "RightUpperArm", "RightArm", "Right Upper Arm", "RightArm" },
	["LeftLowerArm"] = { "LeftLowerArm", "LeftLowerArm" },
	["RightLowerArm"] = { "RightLowerArm", "RightLowerArm" },
	["LeftUpperLeg"] = { "LeftUpperLeg", "LeftLeg", "Left Upper Leg", "LeftLeg" },
	["RightUpperLeg"] = { "RightUpperLeg", "RightLeg", "Right Upper Leg", "RightLeg" },
	["LeftLowerLeg"] = { "LeftLowerLeg", "LeftLowerLeg" },
	["RightLowerLeg"] = { "RightLowerLeg", "RightLowerLeg" },
	["LeftFoot"] = { "LeftFoot", "Left Foot" },
	["RightFoot"] = { "RightFoot", "Right Foot" },
	["Torso"] = { "Torso", "UpperTorso", "LowerTorso", "Chest" },
	["RootPart"] = { "HumanoidRootPart", "RootPart", "Torso", "LowerTorso", "UpperTorso" },
}

-- Utilities
local function isAdmin(player)
	return player and allowedAdmins[player.UserId] == true
end

local function normalizeName(str)
	return string.lower((tostring(str):gsub("%s+", ""):gsub("_", ""):gsub("%W", "")))
end

-- Robust retrieval of player's summit count (leaderstats or attributes; coerces strings)
local function getPlayerSummitLevel(player)
	if not player then
		return 0
	end
	local candidateNames = { "Summits", "Summit", "summits", "summit", "SummitCount", "summitCount" }

	-- leaderstats
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		for _, name in ipairs(candidateNames) do
			local v = stats:FindFirstChild(name)
			if v and (v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue")) then
				local raw = v.Value
				local n = tonumber(raw) or raw
				if type(n) == "number" then
					if DEBUG_AURA then
						print("[Aura] read summit from leaderstats:", player.Name, name, n)
					end
					return n
				end
			end
		end
	end

	-- attributes fallback
	for _, name in ipairs(candidateNames) do
		local attr = player:GetAttribute(name)
		if attr ~= nil then
			local n = tonumber(attr) or attr
			if type(n) == "number" then
				if DEBUG_AURA then
					print("[Aura] read summit from attribute:", player.Name, name, n)
				end
				return n
			end
		end
	end

	if DEBUG_AURA then
		print("[Aura] summit not found for:", player.Name)
	end
	return 0
end

-- Safe getTargetPart: uses aliases, exact match, normalized fallback, attachment fallback
local function getTargetPart(character, templateName)
	if not character or not templateName then
		return nil
	end

	-- Build small list of alias-keys to try (no ambiguous table.insert usage)
	local aliasKeysToTry = {
		templateName,
		(templateName and templateName:gsub("%s+", "") or ""),
		(templateName and templateName:gsub("%s+", " ") or ""),
	}

	-- Try alias lookup
	for _, key in ipairs(aliasKeysToTry) do
		local aliases = PART_NAME_ALIASES[key]
		if aliases then
			for _, alias in ipairs(aliases) do
				local found = character:FindFirstChild(alias)
				if found and found:IsA("BasePart") then
					return found
				end
			end
		end
	end

	-- Try exact child name
	local exact = character:FindFirstChild(templateName)
	if exact and exact:IsA("BasePart") then
		return exact
	end

	-- Normalized name match across children
	local wantNorm = normalizeName(templateName)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") and normalizeName(child.Name) == wantNorm then
			return child
		end
	end

	-- Attachment fallback: if any BasePart contains an Attachment matching normalized templateName
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") then
			for _, c in ipairs(child:GetChildren()) do
				if c:IsA("Attachment") and normalizeName(c.Name) == wantNorm then
					return child
				end
			end
		end
	end

	-- Final fallback: try common R15 names directly that might map to templateName
	local commonNames = {
		"Head",
		"LeftUpperArm",
		"LeftLowerArm",
		"LeftHand",
		"RightUpperArm",
		"RightLowerArm",
		"RightHand",
		"LeftUpperLeg",
		"LeftLowerLeg",
		"LeftFoot",
		"RightUpperLeg",
		"RightLowerLeg",
		"RightFoot",
		"UpperTorso",
		"LowerTorso",
		"Torso",
		"HumanoidRootPart",
		"RootPart",
	}
	for _, n in ipairs(commonNames) do
		local c = character:FindFirstChild(n)
		if c and c:IsA("BasePart") and normalizeName(n) == wantNorm then
			return c
		end
	end

	-- debug list of available children
	if DEBUG_AURA then
		local childNames = {}
		for _, c in ipairs(character:GetChildren()) do
			table.insert(childNames, c.Name)
		end
		warn(
			("Aura part '%s' requested but target part not found on %s; Available parts: %s"):format(
				templateName,
				character.Name,
				table.concat(childNames, ", ")
			)
		)
	end

	return nil
end

-- Remove cloned aura objects and clear activeAuras table for the player
local function removeAllAuras(character)
	if not character then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if player and activeAuras[player.UserId] then
		for _, inst in ipairs(activeAuras[player.UserId]) do
			if inst and inst.Parent then
				inst:Destroy()
			end
		end
		activeAuras[player.UserId] = {}
	end

	-- defensive cleanup: remove any child that contains "Aura_"
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			for _, obj in ipairs(part:GetChildren()) do
				if tostring(obj.Name):find("Aura_") then
					obj:Destroy()
				end
			end
		end
	end
end

-- Permission check
local function canPlayerAccessAura(player, auraName)
	if isAdmin(player) then
		return true
	end
	local summitValue = getPlayerSummitLevel(player)
	for _, a in ipairs(AURA_REQUIREMENTS) do
		if a.name == auraName then
			return summitValue >= a.summit
		end
	end
	return false
end

-- Apply aura by cloning Attachments and supported effects from template parts to character parts
local function giveAuraToPlayer(player, auraName)
	if not player or not player.Character then
		return
	end
	local character = player.Character
	local uid = player.UserId

	activeAuras[uid] = activeAuras[uid] or {}

	-- remove existing aura
	removeAllAuras(character)

	if not auraName or auraName == "none" then
		if DEBUG_AURA then
			print("[Aura] removed aura for", player.Name)
		end
		return
	end

	local auraRoot = script:FindFirstChild("Auras")
	if not auraRoot then
		warn("[Aura] script.Auras folder missing! Create a folder named 'Auras' under this Script.")
		return
	end

	local auraFolder = auraRoot:FindFirstChild(auraName)
	if not auraFolder then
		warn("[Aura] aura folder not found:", auraName)
		return
	end

	-- Short wait to reduce race vs character creation
	for i = 1, 6 do
		if
			character:FindFirstChild("HumanoidRootPart")
			or character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("Torso")
		then
			break
		end
		task.wait(0.06)
	end

	for _, templatePart in ipairs(auraFolder:GetChildren()) do
		if not templatePart:IsA("BasePart") then
			-- skip non-BasePart at this top-level of the aura folder
			continue
		end

		local templateName = templatePart.Name

		-- allow template names from the allowed list (support normalized variants)
		if not ALLOWED_BODY_PARTS[templateName] and not ALLOWED_BODY_PARTS[templateName:gsub("%s+", "")] then
			if DEBUG_AURA then
				warn("[Aura] template part not allowed, skipping:", templateName)
			end
			continue
		end

		local target = getTargetPart(character, templateName)
		if not target then
			if DEBUG_AURA then
				warn(
					("Aura part '%s' requested but target not found for %s; skipping."):format(
						templateName,
						player.Name
					)
				)
			end
			continue
		end

		-- Clone attachments and effect instances
		for _, child in ipairs(templatePart:GetChildren()) do
			if child:IsA("Attachment") then
				local cloned = child:Clone()
				cloned.Name = "Aura_" .. auraName .. "_" .. templateName .. "_" .. child.Name
				cloned.Parent = target
				table.insert(activeAuras[uid], cloned)
			end

			if
				child:IsA("ParticleEmitter")
				or child:IsA("PointLight")
				or child:IsA("SurfaceLight")
				or child:IsA("Fire")
				or child:IsA("Smoke")
				or child:IsA("Sparkles")
				or child:IsA("Beam")
			then
				local clonedEffect = child:Clone()
				clonedEffect.Name = "Aura_" .. auraName .. "_" .. templateName .. "_" .. child.Name
				clonedEffect.Parent = target
				table.insert(activeAuras[uid], clonedEffect)
			end
		end
	end

	if DEBUG_AURA then
		print(("✨ %s equipped %s (instances=%d)"):format(player.Name, auraName, #activeAuras[uid]))
	end
end

-- Build list for UI
local function getAvailableAuras(player)
	local summit = getPlayerSummitLevel(player)
	local list = {}
	for _, a in ipairs(AURA_REQUIREMENTS) do
		table.insert(list, {
			name = a.name,
			requirement = a.summit,
			color = a.color,
			emoji = a.emoji,
			unlocked = (isAdmin(player) or summit >= a.summit),
		})
	end
	return list, summit
end

-- Remote handlers
auraSelectionRemote.OnServerEvent:Connect(function(player, auraName)
	if type(auraName) ~= "string" then
		return
	end
	if auraName ~= "none" and not canPlayerAccessAura(player, auraName) then
		warn("❌", player.Name, "no permission for", auraName, "(summit:", getPlayerSummitLevel(player), ")")
		return
	end
	playerAuraOverrides[player.UserId] = auraName
	giveAuraToPlayer(player, auraName)
end)

getAurasRemote.OnServerInvoke = function(player)
	return getAvailableAuras(player)
end

-- Character and player lifecycle
local function onCharacterAdded(player, character)
	task.wait(0.8)
	local override = playerAuraOverrides[player.UserId]
	if override and canPlayerAccessAura(player, override) then
		giveAuraToPlayer(player, override)
	end
	task.delay(1.5, function()
		if player and player.Parent then
			createAuraGUIRemote:FireClient(player)
		end
	end)
end

local function onPlayerAdded(player)
	activeAuras[player.UserId] = {}
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
	if player.Character then
		task.spawn(function()
			onCharacterAdded(player, player.Character)
		end)
	end

	-- Chat debug commands
	player.Chatted:Connect(function(message)
		if not message then
			return
		end
		local m = string.lower(message)
		if m == "/checkaura" then
			local summit = getPlayerSummitLevel(player)
			local cur = playerAuraOverrides[player.UserId] or "none"
			local gui = Instance.new("ScreenGui")
			gui.Name = "AuraCheckGui"
			gui.Parent = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 2)
			local frame = Instance.new("TextLabel")
			frame.Size = UDim2.new(0, 420, 0, 80)
			frame.Position = UDim2.new(0.5, -210, 0.5, -40)
			frame.TextScaled = true
			frame.BorderSizePixel = 2
			frame.BorderColor3 = Color3.new(1, 1, 1)
			frame.BackgroundColor3 = Color3.fromRGB(70, 70, 180)
			frame.TextColor3 = Color3.new(1, 1, 1)
			frame.Text = "✨ Current Aura: " .. tostring(cur) .. "\nSummit: " .. tostring(summit)
			frame.Parent = gui
			Debris:AddItem(gui, 4)
		elseif m == "/resetaura" then
			playerAuraOverrides[player.UserId] = nil
			if player.Character then
				removeAllAuras(player.Character)
			end
			--print("🔄", player.Name, "reset aura")
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end

Players.PlayerRemoving:Connect(function(player)
	playerAuraOverrides[player.UserId] = nil
	activeAuras[player.UserId] = nil
end)
