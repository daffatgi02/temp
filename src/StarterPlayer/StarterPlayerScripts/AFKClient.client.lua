local uis = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local AFKSystem = RS:WaitForChild("AFKSystem")
local AFKEvent = AFKSystem:WaitForChild("AFKEvent")

uis.WindowFocused:Connect(function()
	AFKEvent:FireServer(false)
end)

uis.WindowFocusReleased:Connect(function()
	AFKEvent:FireServer(true)
end)
