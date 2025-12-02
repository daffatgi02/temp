local button = script.Parent

local HoverSFX = Instance.new("Sound")
HoverSFX.SoundId = "rbxassetid://408524543"
HoverSFX.Parent = button

local ClickSFX = Instance.new("Sound")
ClickSFX.SoundId = "rbxassetid://6324790483"
ClickSFX.Parent = button

button.MouseEnter:Connect(function()
	HoverSFX:Play()
end)

button.MouseButton1Click:Connect(function()
	ClickSFX:Play()
end)
