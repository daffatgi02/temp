local RS = game:GetService("ReplicatedStorage")
local AFKSystem = RS:WaitForChild("AFKSystem")
local AFKEvent = AFKSystem:WaitForChild("AFKEvent")
local AFKTemplate = AFKSystem:WaitForChild("AFKTemplate")

local originalMaterials = {}
local afkAnimations = {}

local function getOrCloneAFK(head)
	local afkBill = head:FindFirstChild("AFKTemplate")
	if not afkBill then
		afkBill = AFKTemplate:Clone()
		afkBill.Name = "AFKTemplate"
		afkBill.Parent = head
	end
	return afkBill
end

game.Players.PlayerRemoving:Connect(function(player)
	originalMaterials[player] = nil
	afkAnimations[player] = nil
end)

AFKEvent.OnServerEvent:Connect(function(player, isAFK)
	local chara = player.Character
	if not chara then return end

	local head = chara:FindFirstChild("Head")
	local humanoid = chara:FindFirstChildOfClass("Humanoid")
	if not head or not humanoid then return end

	local afkBill = getOrCloneAFK(head)
	local label = afkBill:FindFirstChild("AFKLabel")

	if isAFK then
		if afkBill:IsA("BillboardGui") then
			if label then label.Visible = true end
		else
			afkBill.Enabled = true
		end

		originalMaterials[player] = originalMaterials[player] or {}
		for _, base in ipairs(chara:GetDescendants()) do
			if base:IsA("BasePart") then
				if not originalMaterials[player][base] then
					originalMaterials[player][base] = base.Material
				end
				base.Material = Enum.Material.ForceField
			end
		end

		if not afkAnimations[player] then
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if animator then
				local anim = animator:LoadAnimation(script:WaitForChild("AFKAnimation"))
				anim:Play()
				afkAnimations[player] = anim
			end
		else
			afkAnimations[player]:Play()
		end

	else
		if afkBill:IsA("BillboardGui") then
			if label then label.Visible = false end
		else
			afkBill.Enabled = false
		end

		if originalMaterials[player] then
			for base, mat in pairs(originalMaterials[player]) do
				if base and base.Parent then
					base.Material = mat
				end
			end
			originalMaterials[player] = nil
		end

		if afkAnimations[player] then
			afkAnimations[player]:Stop()
			afkAnimations[player] = nil
		end
	end
end)