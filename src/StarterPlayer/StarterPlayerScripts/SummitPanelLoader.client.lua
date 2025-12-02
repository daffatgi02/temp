-- StarterPlayer -> StarterPlayerScripts -> SummitPanelLoader (CLEAN)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local OpenPanelRemote = ReplicatedStorage:WaitForChild("OpenSummitPanel", 10)
local SummitPanelModule = ReplicatedStorage:WaitForChild("SummitPanelClient", 10)

if not OpenPanelRemote or not SummitPanelModule then
	warn("⚠️ [Summit Panel] Required modules not found!")
	return
end

local success, SummitPanel = pcall(function()
	return require(SummitPanelModule)
end)

if not success then
	warn("❌ [Summit Panel] Failed to load module:", SummitPanel)
	return
end

OpenPanelRemote.OnClientEvent:Connect(function()
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
	local existing = PlayerGui:FindFirstChild("SummitAdminPanel")

	if existing then
		existing:Destroy()
		return
	end

	pcall(function()
		SummitPanel.Open(LocalPlayer)
	end)
end)

--print("✅ Summit Panel loaded!")