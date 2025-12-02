-- Checkpoint Sound Effects System
-- Plays sound only for the player who touches checkpoint/summit

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- ========================================
-- SOUND CONFIGURATION
-- ========================================

-- Ganti asset ID ini dengan sound yang kamu inginkan
local CHECKPOINT_SOUND_ID = "rbxassetid://6979299092" -- Contoh: success sound
local SUMMIT_SOUND_ID = "rbxassetid://129653888707716" -- Contoh: victory sound

local CHECKPOINT_VOLUME = 0.5
local SUMMIT_VOLUME = 0.7

-- ========================================
-- CREATE SOUND INSTANCES
-- ========================================

local checkpointSound = Instance.new("Sound")
checkpointSound.Name = "CheckpointSound"
checkpointSound.SoundId = CHECKPOINT_SOUND_ID
checkpointSound.Volume = CHECKPOINT_VOLUME
checkpointSound.Parent = SoundService

local summitSound = Instance.new("Sound")
summitSound.Name = "SummitSound"
summitSound.SoundId = SUMMIT_SOUND_ID
summitSound.Volume = SUMMIT_VOLUME
summitSound.Parent = SoundService

-- ========================================
-- REMOTE EVENTS
-- ========================================

local playCheckpointSoundRemote = ReplicatedStorage:WaitForChild("PlayCheckpointSound")
local playSummitSoundRemote = ReplicatedStorage:WaitForChild("PlaySummitSound")

-- ========================================
-- SOUND PLAYBACK FUNCTIONS
-- ========================================

local function playCheckpointSound()
	if checkpointSound then
		-- Stop jika masih playing untuk prevent overlap
		if checkpointSound.IsPlaying then
			checkpointSound:Stop()
		end
		checkpointSound:Play()
	end
end

local function playSummitSound()
	if summitSound then
		-- Stop jika masih playing untuk prevent overlap
		if summitSound.IsPlaying then
			summitSound:Stop()
		end
		summitSound:Play()
	end
end

-- ========================================
-- EVENT CONNECTIONS
-- ========================================

playCheckpointSoundRemote.OnClientEvent:Connect(playCheckpointSound)
playSummitSoundRemote.OnClientEvent:Connect(playSummitSound)
