local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Plr = Players.LocalPlayer
local CanAskCarry = Plr:WaitForChild("CanAskCarry")
local CarryReplic = ReplicatedStorage.CarryReplic
local CarryRemotes = CarryReplic.CarryRemotes
local CarryChoices = CarryReplic.CarryChoices
local CarryRemotes = CarryReplic.CarryRemotes
local CarryRemote = CarryRemotes.CarryRemote
local CarryFunction = CarryRemotes.CarryFunction
local buttontemplate = ReplicatedStorage.CarryReplic.buttontemplate
local ChoicesFrame = script.Parent.Choices
local Choices_TargetName = ChoicesFrame.carrytarget
local Choices_OptionsList = ChoicesFrame.carryPick
local Choices_CloseBtn = ChoicesFrame.close
for _,module in ipairs(CarryChoices:GetChildren()) do
	local OptionGui = buttontemplate:Clone()
	OptionGui.Name = module.Name
	OptionGui.optionName.Text = module.Name
	OptionGui.Visible = true
	
	OptionGui.MouseButton1Click:Connect(function()
		local target = Players:WaitForChild(Choices_TargetName.Text)
		CarryRemote:FireServer({cmd="AskCarry", targetPlr=target, carrychoicesss=module})
		CarryRemote:FireServer({cmd="CancelAll"})
		ChoicesFrame.Visible = false
	end)
	OptionGui.Parent = Choices_OptionsList
end