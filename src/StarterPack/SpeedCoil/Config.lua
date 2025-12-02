-- ============================================================================
-- SpeedCoil Config
-- ============================================================================
local Config = {}

-- SPEED SETTINGS
Config.BaseWalkSpeed = 16 -- WalkSpeed tanpa item (JANGAN DIUBAH!)
Config.BoostWalkSpeed = 35 -- WalkSpeed saat equipped (JANGAN DIUBAH!)
Config.SwimmingSpeed = 25 -- Swimming speed saat equipped (CONFIGURABLE!)

-- SMOKE SETTINGS
Config.Smoke = {
	enabled = false,
	minSpeed = 10,
	color = Color3.fromRGB(100, 200, 255),
	opacity = 0.3,
	size = 0.8,
	riseVelocity = 3,
}

return Config
