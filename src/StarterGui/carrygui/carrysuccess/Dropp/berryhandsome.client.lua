local button = script.Parent
local bgFrame = button.Parent:FindFirstChild("BG")
local HoverSFX = button:FindFirstChild("HoverSFX")
local ClickSFX = button:FindFirstChild("ClickSFX")

local originalButtonSize = UDim2.new(1.027, 0, 1.016, 0)
local zoomSize = UDim2.new(1.1, 0, 1.1, 0)

local originalBgSize = UDim2.new(1.02, 0, 1, 0)

if HoverSFX then
	HoverSFX.SoundId = "rbxassetid://3199281218"
else
	warn("HoverSFX not found!")
end

if ClickSFX then
	ClickSFX.SoundId = "rbxassetid://6324790483"
else
	warn("ClickSFX not found!")
end

button.MouseEnter:Connect(function()
	button:TweenSize(zoomSize, "Out", "Quad", 0.2, true)
	if bgFrame then
		bgFrame:TweenSize(zoomSize, "Out", "Quad", 0.2, true)
	end
	if HoverSFX then
		HoverSFX:Play()
	end
end)

button.MouseLeave:Connect(function()
	button:TweenSize(originalButtonSize, "Out", "Quad", 0.2, true)
	if bgFrame then
		bgFrame:TweenSize(originalBgSize, "Out", "Quad", 0.2, true)
	end
end)

button.MouseButton1Click:Connect(function()
	if ClickSFX then
		ClickSFX:Play()
	end
end)
