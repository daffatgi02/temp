local button = script.Parent
local originalSize = UDim2.new(0.245, 0, 0.293, 0)
local zoomSize = UDim2.new(0.28, 0, 0.33, 0)

local HoverSFX = Instance.new("Sound")
HoverSFX.SoundId = "rbxassetid://408524543"
HoverSFX.Parent = button

local ClickSFX = Instance.new("Sound")
ClickSFX.SoundId = "rbxassetid://6324790483"
ClickSFX.Parent = button

button.MouseEnter:Connect(function()
	button:TweenSize(zoomSize, "Out", "Quad", 0.2, true)
	if HoverSFX then
		HoverSFX:Play()
	end
end)

button.MouseLeave:Connect(function()
	button:TweenSize(originalSize, "Out", "Quad", 0.2, true)
end)

button.MouseButton1Click:Connect(function()
	if ClickSFX then
		ClickSFX:Play()
	end
end)
