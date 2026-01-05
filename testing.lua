if not game:IsLoaded() then
    game.Loaded:Wait()
end

local gameId = tostring(game.GameId)
local version = _G.HAZE_VERSION or "mjzzpe2l"
local token = "09be995a5f3610d13188d05536d39c6d8226947f4f9b34e8f0cac45b420e665d"

local url = "https://haze.wtf/api/script/" .. version .. "/" .. gameId .. "?token=" .. token

print("URL:")
print(url)

local response = game:HttpGet(url)

print("SCRIPT RESPONSE START")
print(response)
print("SCRIPT RESPONSE END")
