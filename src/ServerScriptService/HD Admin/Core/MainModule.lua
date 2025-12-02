-- Kode dengan Debug Timer
local startTime = os.clock()
print("HD MainModule: Memulai require asset...")

local assetModule = require(3239236979)

print(string.format(
	"HD MainModule: ✅ Berhasil require asset 3239236979. Waktu download: %.3f detik", 
	os.clock() - startTime
	))

return assetModule