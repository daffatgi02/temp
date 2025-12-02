local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
wait(3)
StarterGui:SetCore("AvatarContextMenuEnabled", true)
StarterGui:SetCore("RemoveAvatarContextMenuOption", Enum.AvatarContextMenuOption.Chat)
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local canCarryRequest = player:WaitForChild("CanAskCarry")
local carryReplic = ReplicatedStorage.CarryReplic
local carryRemotes = carryReplic.CarryRemotes
local carryChoices = carryReplic.CarryChoices
local carryRemote = carryRemotes.CarryRemote
local carryFunction = carryRemotes.CarryFunction

local choicesFrame = script.Parent.Choices
choicesFrame.Visible = false
local choicesTargetName = choicesFrame.carrytarget
local choicesOptionsList = choicesFrame.carryPick
local choicesCloseBtn = choicesFrame.close
local carryNotifFrame = script.Parent.carryNotif
carryNotifFrame.Visible = false
local carryNotifTitle = carryNotifFrame.None
local carryNotifDesc = carryNotifFrame.None1
local carryNotifAcceptBtn = carryNotifFrame.accept
local carryNotifDeclineBtn = carryNotifFrame.decline
local notifySent = script.NotifySent
local choiceModule = script.ChoiceModule
local carryCheck = script.carrycheck
local carrySuccessFrame = script.Parent.carrysuccess
carrySuccessFrame.Visible = false
local carrySuccessDesc = carrySuccessFrame.Dropp
local carrysucesstxt = carrySuccessDesc.TextLabel
local carrySuccessCancel = carrySuccessFrame.Dropp

while wait() do
	if player.Character then
		break
	end
end

local character = player.Character
local canCarry = character:WaitForChild("Carryble")
local requestRate = 5
local waitingForRequestRate = false
local lastMessageSentByPlayer

local be = Instance.new("BindableEvent") 
local ue = Instance.new("BindableEvent")

local function unsync(player)
	game.ReplicatedStorage:FindFirstChild("Unsync"):FireServer(player)
end

local function sync(t) 
	game.ReplicatedStorage:FindFirstChild("Sync"):FireServer(t)
end

ue.Event:Connect(unsync)
be.Event:Connect(sync) 

StarterGui:SetCore("AddAvatarContextMenuOption", {"Unsync", ue})
StarterGui:SetCore("AddAvatarContextMenuOption", {"Sync", be})


local carryOptionBindableEvent = Instance.new("BindableEvent")

local function carryOptionAction(targetPlayer)
	local function execute()
		if canCarryRequest.Value and not waitingForRequestRate then
			carryRemote:FireServer({cmd = "PromptAction"})
			waitingForRequestRate = true
			choicesFrame.Visible = true
			choicesTargetName.Text = targetPlayer.Name
			wait(requestRate)
			waitingForRequestRate = false
		end
	end

	if targetPlayer ~= player then
		if notifySent.Value then
			if notifySent.Value.UserId ~= targetPlayer.UserId then
				execute()
			end
		else
			execute()
		end
	end
end

carryOptionBindableEvent.Event:Connect(carryOptionAction)

local carryOption = {"Carry", carryOptionBindableEvent}
StarterGui:SetCore("AddAvatarContextMenuOption", carryOption)
mouse.Button1Down:Connect(function()
	if mouse.Target then
		local targetCharacter = mouse.Target.Parent
		local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)

		-- Allow avatar menu to open for any other player
		-- Remove the notifySent.Value check that was blocking menu after drop
		if targetPlayer and targetPlayer.UserId ~= player.UserId then
			-- Only block if we're currently in an active carry notification from this specific player
			local blockMenu = false
			if notifySent.Value and notifySent.Value.UserId == targetPlayer.UserId then
				-- Don't open menu if we already have a pending request from this player
				blockMenu = true
			end

			if not blockMenu then
				StarterGui:SetCore("AvatarContextMenuTarget", targetPlayer)
			end
		end
	end
end)

choicesCloseBtn.MouseButton1Click:Connect(function()
	carryRemote:FireServer({cmd = "CancelAll"})
	choicesFrame.Visible = false
end)

carryNotifDeclineBtn.MouseButton1Click:Connect(function()
	notifySent.Value = nil
	choiceModule.Value = nil
	carryRemote:FireServer({cmd = "CancelAll"})
	carryNotifFrame.Visible = false
end)

carryNotifAcceptBtn.MouseButton1Click:Connect(function()
	if notifySent.Value and choiceModule.Value then
		carryRemote:FireServer({cmd = "Carry", firstPlr = notifySent.Value, carrychoicesss = choiceModule.Value})
	else
		carryRemote:FireServer({cmd = "CancelAll"})
	end

	carryCheck.Value = false
	wait(0.05)
	carryCheck.Value = true
	carryNotifFrame.Visible = false
end)

carrySuccessCancel.MouseButton1Click:Connect(function()
	carryRemote:FireServer({cmd = "Declinecarry"})
	notifySent.Value = nil
	choiceModule.Value = nil
	carrySuccessFrame.Visible = false
end)

carryCheck.Changed:Connect(function(newValue)
	if newValue and notifySent.Value and choiceModule.Value then
		carrySuccessFrame.Visible = true
		carrysucesstxt.Text = "Drop " .. notifySent.Value.Name
	else
		carrySuccessFrame.Visible = false
		carrysucesstxt.Text = ""
	end
end)

notifySent.Changed:Connect(function(value)
	if value then
		lastMessageSentByPlayer = value
	end
end)

canCarry.Changed:Connect(function(value)
	if value then
		carryCheck.Value = false
		notifySent.Value = nil
		choiceModule.Value = nil
	end
end)

carryRemote.OnClientEvent:Connect(function(args)
	local success, result = pcall(function()
		local cmd = args.cmd

		if cmd == "GetMessage" then
			local messageSentBy = args.messageSentBy
			local carryChoice = args.carrychoicesss

			notifySent.Value = messageSentBy
			choiceModule.Value = carryChoice
			carryNotifFrame.Visible = true
			carryNotifTitle.Text = "Carry Request From: " .. messageSentBy.Name
			carryNotifDesc.Text = messageSentBy.Name .. " wants to carry you. with " .. carryChoice.Name .. ""

			local NotifSFX = carryNotifFrame:FindFirstChild("NotifSFX")
			if NotifSFX then
				NotifSFX.SoundId = "rbxassetid://17208361335"
				NotifSFX:Play()
			end

		elseif cmd == "Messagesserror" then
			local targetPlayer = args.targetPlr

		elseif cmd == "GetCarryInfo" then
			local otherPlayer = args.otherPlr
			local carryChoice = args.carrychoicesss

			choiceModule.Value = carryChoice
			notifySent.Value = otherPlayer
			carryCheck.Value = false
			wait(0.05)
			carryCheck.Value = true

		elseif cmd == "DestroyCarryInfo" then
			notifySent.Value = nil
			choiceModule.Value = nil
		end
	end)

	if not success then
		warn(result)
	end
end)
