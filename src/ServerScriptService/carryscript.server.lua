local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarryReplic = ReplicatedStorage.CarryReplic
local CarryRemotes = CarryReplic.CarryRemotes
local CarryRemote = CarryRemotes.CarryRemote 

function PlayerAddedFunction(plr: Player)
	local CanAskCarry = Instance.new("BoolValue", plr)
	CanAskCarry.Name = "CanAskCarry"
	CanAskCarry.Value = true

	plr.CharacterAdded:Connect(function(character: Model)
		local Carryble = Instance.new("BoolValue", character)
		Carryble.Name = "Carryble"
		Carryble.Value = true
	end)
end

for _, player: Player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerAddedFunction, player)
end
Players.PlayerAdded:Connect(PlayerAddedFunction)

CarryRemote.OnServerEvent:Connect(function(plr: Player, args: {})
	local Work, Result = pcall(function()
		local CanAskCarry = plr:WaitForChild("CanAskCarry")
		local Carryble = plr.Character:WaitForChild("Carryble")
		local cmd = args.cmd

		if cmd == "AskCarry" then
			local targetPlr = args.targetPlr
			local carrychoicesss = args.carrychoicesss

			local isCarrying = Carryble.Value == false
			local targetCanAskCarry = targetPlr and targetPlr:FindFirstChild("CanAskCarry") and targetPlr.CanAskCarry.Value
			local targetCarryble = targetPlr.Character:FindFirstChild("Carryble") and targetPlr.Character.Carryble.Value

			if targetPlr and targetCanAskCarry and targetCarryble and not isCarrying then
				CarryRemote:FireClient(targetPlr, {cmd="GetMessage", messageSentBy=plr, carrychoicesss=carrychoicesss})
				targetPlr.CanAskCarry.Value = false
			else
				CarryRemote:FireClient(plr, {cmd="Messagesserror", targetPlr=targetPlr})
			end
		elseif cmd == "CancelAll" then
			CanAskCarry.Value = true
		elseif cmd == "Carry" then
			CanAskCarry.Value = true
			Carryble.Value = false
			local firstPlr = args.firstPlr
			local carrychoicesss = args.carrychoicesss
			if firstPlr then
				firstPlr.CanAskCarry.Value = true
				firstPlr.Character.Carryble.Value = false
				CarryRemote:FireClient(plr, {cmd="GetCarryInfo", otherPlr=firstPlr, carrychoicesss=carrychoicesss})
				CarryRemote:FireClient(firstPlr, {cmd="GetCarryInfo", otherPlr=plr, carrychoicesss=carrychoicesss})
			end
			local OptionModuleArgs = {
				["Players"] = {
					["First"] = firstPlr,
					["Second"] = plr,
				}
			}
			require(carrychoicesss)(OptionModuleArgs)
		elseif cmd == "Declinecarry" then
			Carryble.Value = true
		elseif cmd == "PromptAction" then
			CanAskCarry.Value = false
		end
	end)

	if not Work then
		warn(Result)
	end
end)
