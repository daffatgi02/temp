--Get services
local TextService = game:GetService("TextService")

--Get path of the objects
local Remote = script.Parent.RemoteFunction

local Text = script.Parent.Text
local SurfaceGui = Text.SurfaceGui
local TextLabel = SurfaceGui.TextLabel

local Tool = script.Parent

--SCRIPT
--Text filter and remember not to skip this step, otherwise, your account may be at risk of being banned
local function Filter(Letters, UserId)
	local FilteredText = ""
	
	local IsSuccess, ErrorMessage = pcall(function() --We use pcall to prevent failures error that causes script error
		FilteredText = TextService:FilterStringAsync(Letters, UserId)
		FilteredText = FilteredText:GetNonChatStringForBroadcastAsync()
	end)
	
	return IsSuccess, ErrorMessage, FilteredText --Return results
end

--When LocalScript invoked the RemoteFunction
Remote.OnServerInvoke = function(Player, Letters) --Get letters from client
	local IsSuccess, ErrorMessage, FilteredText = Filter(Letters, Player.UserId) --Call Filter function and get results
	
	if IsSuccess then --If filtered success
		TextLabel.Text = FilteredText
		return true
		
	else --If filtered fail
		return false, ErrorMessage
		
	end
end