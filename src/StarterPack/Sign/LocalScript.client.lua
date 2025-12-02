--Get services
local PlayerService = game:GetService("Players")

--Get path of the objects
local Tool = script.Parent
local Remote = script.Parent:WaitForChild("RemoteFunction")

Tool.Equipped:Connect(function()
	--Get player
	local OurPlayer = PlayerService.LocalPlayer
	
	--Find old gui to make sure if it wasnt destroyed before and you can remove this step if you want
	local FoundOldGui = OurPlayer.PlayerGui:FindFirstChild("SignGui")
	if FoundOldGui then
		FoundOldGui:Destroy() --if old gui was found then destroy it
	end
	
	--Dupe the gui
	local ClonedGui = script.SignGui:Clone()
	ClonedGui.Parent = OurPlayer.PlayerGui --Set the gui parent and make it appear on player screen

	--Get path of the objects
	local TextBox = ClonedGui.Frame.TextBox
	local TextButton = ClonedGui.Frame.TextButton
	local CloseButton = ClonedGui.Frame.CloseButton

	--When player clicked submit button
	TextButton.MouseButton1Click:Connect(function()
		local Letters = TextBox.Text --Get letters from textbox
		local IsSuccessfullyChanged, ErrorMessage = Remote:InvokeServer(Letters) --Fire remote and get result from server script

		if IsSuccessfullyChanged then --If server result true
			TextButton.Text = "Successfully changed!"
			wait(1)
			TextButton.Text = "Submit"

		else --If server result false
			TextButton.Text = "Failed!"
			wait(1)
			TextButton.Text = "Submit"
			
			print(ErrorMessage)
		end

	end)

	--When player clicked red X button
	CloseButton.MouseButton1Click:Connect(function()
		ClonedGui:Destroy()

	end)

end)

Tool.Unequipped:Connect(function() --Destroy SignGui when player unequipped the tool (if found)
	local OurPlayer = PlayerService.LocalPlayer
	
	local Found = OurPlayer.PlayerGui:FindFirstChild("SignGui")
	if Found then
		Found:Destroy() --if gui was found then destroy it
	end
end)