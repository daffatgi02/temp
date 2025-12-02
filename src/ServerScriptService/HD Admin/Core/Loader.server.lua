	-- Kode Loader dengan Debug Timer
local totalStartTime = os.clock()
--print(string.format("HD Loader: Skrip dimulai."))

local core = script.Parent
local loader = core.Parent

--print(string.format("HD Loader: [START] Requiring MainModule... (Elapsed: %.3fs)", os.clock() - totalStartTime))
-- Baris di bawah ini akan memanggil skrip MainModule dan menunggu...
local mainModule = require(core:WaitForChild("MainModule"))
--print(string.format("HD Loader: [FINISH] MainModule telah di-require. (Elapsed: %.3fs)", os.clock() - totalStartTime))

--print(string.format("HD Loader: [START] Memanggil mainModule.initialize()... (Elapsed: %.3fs)", os.clock() - totalStartTime))
mainModule.initialize(loader)
--print(string.format("HD Loader: [FINISH] Inisialisasi HD Admin selesai. (Elapsed: %.3fs)", os.clock() - totalStartTime))