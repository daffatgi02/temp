-- ServerScript untuk auto-apply speed
local tool = script.Parent
local Config = require(tool:WaitForChild("Config"))
local speedboostscript = tool:WaitForChild("SpeedBoostScript")

tool.Equipped:Connect(function()
	local player = game.Players:GetPlayerFromCharacter(tool.Parent)
	if not player then return end

	local character = player.Character
	if not character then return end

	-- Hapus script lama jika ada
	local oldScript = character:FindFirstChild("SpeedBoostScript")
	if oldScript then
		oldScript:Destroy()
	end

	-- Buat script baru dengan speed dari config
	local newScript = speedboostscript:Clone()

	local speedVal = Instance.new("NumberValue")
	speedVal.Name = "SelectedSpeed"
	speedVal.Value = Config.BoostWalkSpeed
	speedVal.Parent = newScript

	local tooltag = Instance.new("ObjectValue")
	tooltag.Name = "ToolTag"
	tooltag.Value = tool
	tooltag.Parent = newScript

	newScript.Parent = character
	newScript.Disabled = false
end)