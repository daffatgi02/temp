--[[
    BoomBox Server Script - Music Follows Player
    Music continues and follows player even when unequipped
--]]

local Tool = script.Parent
local Remote = Tool:WaitForChild("BoomboxRemote")
local Handle = Tool:WaitForChild("Handle")

-- Variables
local currentSound = nil
local playlist = {}
local currentIndex = 1
local isPlaying = false
local isPaused = false
local owner = nil
local soundAttachment = nil

-- Create Sound object that follows player
local function createSound()
	if currentSound then
		currentSound:Destroy()
	end

	-- Create attachment to follow player
	if soundAttachment then
		soundAttachment:Destroy()
	end

	-- Get player's HumanoidRootPart
	local character = owner and owner.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")

	if hrp then
		-- Create attachment on player's root part
		soundAttachment = Instance.new("Attachment")
		soundAttachment.Name = "BoomBoxAttachment"
		soundAttachment.Parent = hrp

		-- Create sound on the attachment
		local sound = Instance.new("Sound")
		sound.Name = "BoomBoxSound"
		sound.Parent = soundAttachment
		sound.Volume = 0.5
		sound.Looped = false
		sound.RollOffMaxDistance = 100
		sound.RollOffMinDistance = 10

		-- Auto-play next song when finished
		sound.Ended:Connect(function()
			playNext()
		end)

		currentSound = sound
		print("Sound created on player's body")
		return sound
	else
		-- Fallback: create on Handle if player not found
		local sound = Instance.new("Sound")
		sound.Name = "BoomBoxSound"
		sound.Parent = Handle
		sound.Volume = 0.5
		sound.Looped = false
		sound.RollOffMaxDistance = 100
		sound.RollOffMinDistance = 10

		sound.Ended:Connect(function()
			playNext()
		end)

		currentSound = sound
		print("Sound created on Handle (fallback)")
		return sound
	end
end

-- Update sound position to follow player
local function updateSoundPosition()
	if not owner then return end

	local character = owner.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")

	if hrp and currentSound then
		-- If sound is not on player, move it
		if currentSound.Parent ~= soundAttachment or not soundAttachment or soundAttachment.Parent ~= hrp then
			local wasPlaying = currentSound.Playing
			local timePos = currentSound.TimePosition
			local soundId = currentSound.SoundId

			-- Recreate sound on player
			createSound()

			-- Restore state
			if soundId ~= "" then
				currentSound.SoundId = soundId
				currentSound.TimePosition = timePos
				if wasPlaying then
					currentSound:Play()
				end
			end
		end
	end
end

-- Play song by ID
local function playSong(audioId)
	if not owner then return end

	-- Make sure sound is on player
	updateSoundPosition()

	if not currentSound then
		currentSound = createSound()
	end

	currentSound:Stop()
	currentSound.SoundId = "rbxassetid://" .. audioId
	currentSound.TimePosition = 0

	wait(0.1)
	currentSound:Play()

	isPlaying = true
	isPaused = false

	print("Playing song:", audioId, "- Following player:", owner.Name)
end

-- Play from playlist
local function playFromPlaylist(index)
	if #playlist == 0 then 
		print("Playlist empty!")
		return 
	end

	index = math.clamp(index, 1, #playlist)
	currentIndex = index

	local song = playlist[index]
	if song and song.id then
		print("Playing from playlist  by nrhd:", song.name, song.id)
		playSong(song.id)

		-- Notify client
		if owner then
			Remote:FireClient(owner, "SongChanged", index, song)
			Remote:FireClient(owner, "PlaybackState", "playing")
		end
	end
end

-- Play next song
function playNext()
	if #playlist == 0 then return end

	currentIndex = currentIndex + 1
	if currentIndex > #playlist then
		currentIndex = 1
	end

	print("Next song, index:", currentIndex)
	playFromPlaylist(currentIndex)
end

-- Play previous song
local function playPrevious()
	if #playlist == 0 then return end

	currentIndex = currentIndex - 1
	if currentIndex < 1 then
		currentIndex = #playlist
	end

	print("Previous song, index:", currentIndex)
	playFromPlaylist(currentIndex)
end

-- Pause
local function pauseMusic()
	if currentSound and isPlaying and not isPaused then
		currentSound:Pause()
		isPaused = true
		if owner then
			Remote:FireClient(owner, "PlaybackState", "paused")
		end
		print("Music paused  by nrhd")
	end
end

-- Resume
local function resumeMusic()
	if currentSound and isPaused then
		currentSound:Resume()
		isPaused = false
		isPlaying = true
		if owner then
			Remote:FireClient(owner, "PlaybackState", "playing")
		end
		print("Music resumed   by nrhd")
	end
end

-- Stop
local function stopMusic()
	if currentSound then
		currentSound:Stop()
	end
	isPlaying = false
	isPaused = false
	if owner then
		Remote:FireClient(owner, "PlaybackState", "stopped")
	end
	print("Music stopped  by nrhd")
end

-- Handle remote events
Remote.OnServerEvent:Connect(function(player, action, ...)
	print("Server received:", action, ...)

	-- Set owner if not set
	if not owner and Tool.Parent and Tool.Parent:IsA("Model") then
		owner = game.Players:GetPlayerFromCharacter(Tool.Parent)
	end

	-- Security check
	if owner and player ~= owner then 
		print("Blocked: Wrong player")
		return 
	end

	if action == "PlayFromPlaylist" then
		local index = ...
		print("Play from playlist, index:", index)
		playFromPlaylist(index or currentIndex)

	elseif action == "Next" then
		playNext()

	elseif action == "Previous" then
		playPrevious()

	elseif action == "Pause" then
		pauseMusic()

	elseif action == "Resume" then
		resumeMusic()

	elseif action == "Stop" then
		stopMusic()

	elseif action == "SetPlaylist" then
		local newPlaylist = ...
		if type(newPlaylist) == "table" then
			playlist = newPlaylist
			print("Playlist updated:", #playlist, "songs")
		end
	end
end)

-- Tool equipped
Tool.Equipped:Connect(function()
	-- Get owner
	if Tool.Parent and Tool.Parent:IsA("Model") then
		owner = game.Players:GetPlayerFromCharacter(Tool.Parent)
		print("Tool equipped by:", owner and owner.Name or "Unknown")
	end

	-- Update sound position to follow player
	updateSoundPosition()

	-- Create sound if needed
	if not currentSound then
		currentSound = createSound()
	end

	-- Send current state to client
	if owner then
		if isPlaying then
			Remote:FireClient(owner, "PlaybackState", isPaused and "paused" or "playing")
			if playlist[currentIndex] then
				Remote:FireClient(owner, "SongChanged", currentIndex, playlist[currentIndex])
			end
		end
	end
end)

-- Tool unequipped - MUSIC KEEPS PLAYING AND FOLLOWS PLAYER!
Tool.Unequipped:Connect(function()
	print("Tool unequipped - music continues and follows player! by nrhd")
	-- Update sound to make sure it's on player's body
	updateSoundPosition()
end)

-- Monitor player position (keep sound attached)
game:GetService("RunService").Heartbeat:Connect(function()
	if isPlaying and owner and owner.Character then
		-- Periodically check if sound needs to be repositioned
		local hrp = owner.Character:FindFirstChild("HumanoidRootPart")
		if hrp and soundAttachment and soundAttachment.Parent ~= hrp then
			updateSoundPosition()
		end
	end
end)

-- Handle player respawn
local function onCharacterAdded(character)
	if not owner then return end

	wait(0.5) -- Wait for character to load

	-- If music was playing, recreate sound on new character
	if isPlaying and currentSound then
		local wasPlaying = currentSound.Playing
		local timePos = currentSound.TimePosition
		local soundId = currentSound.SoundId

		-- Recreate sound
		createSound()

		if soundId ~= "" then
			currentSound.SoundId = soundId
			currentSound.TimePosition = timePos
			if wasPlaying then
				currentSound:Play()
			end
		end

		print("Music restored after respawn")
	end
end

-- Connect character respawn handler
if owner and owner.Character then
	owner.Character:WaitForChild("HumanoidRootPart")
	onCharacterAdded(owner.Character)
end

if owner then
	owner.CharacterAdded:Connect(onCharacterAdded)
end

-- Initial setup
print("BoomBox Server initialized - Music follows player mode by nrhd")
wait(0.5)

-- Wait for owner's character to load
if Tool.Parent and Tool.Parent:IsA("Model") then
	owner = game.Players:GetPlayerFromCharacter(Tool.Parent)
	if owner then
		owner.CharacterAdded:Connect(onCharacterAdded)
	end
end

createSound()