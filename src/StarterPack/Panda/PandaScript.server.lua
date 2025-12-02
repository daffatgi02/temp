-- 🐼 Panda Line System (Clone dari ReplicatedStorage)
local sp = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local debris = game:GetService("Debris")
local numberofpandas = 5
local check = true
local pandas = {}
local deathConnection = nil

-- Ambil MeshPart Panda dari ReplicatedStorage
local pandaFolder = ReplicatedStorage:WaitForChild("Panda")
local pandaTemplate = pandaFolder:WaitForChild("Panda")

function createpanda(follow)
	-- CLONE MESHPART LANGSUNG
	local panda = pandaTemplate:Clone()
	panda.Name = "Panda_Clone"
	panda.Anchored = false
	panda.CanCollide = true

	-- Spawn posisi
	local basePos = follow and follow.Position or Vector3.new(0, 5, 0)
	local spawnPos = Vector3.new(basePos.X + math.random(-3,3), basePos.Y, basePos.Z + math.random(-3,3))
	panda.CFrame = CFrame.new(spawnPos)

	-- Body movers (TUNED untuk movement lebih smooth)
	local bp = Instance.new("BodyPosition")
	bp.MaxForce = Vector3.new(5000, 5000, 5000)  -- ← Ditinggikan sedikit
	bp.P = 3000  -- ← Diturunin biar ga terlalu kaku
	bp.D = 200   -- ← Damping ditinggikan biar smooth
	bp.Position = spawnPos
	bp.Parent = panda

	local bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(4000, 4000, 4000)
	bg.P = 3000  -- ← Diturunin dikit
	bg.D = 100   -- ← Tambah damping biar rotasi smooth
	bg.Parent = panda

	-- Tag follow
	local followTag = Instance.new("ObjectValue")
	followTag.Name = "FollowTag"
	followTag.Value = follow
	followTag.Parent = panda

	panda.Parent = workspace
	table.insert(pandas, panda)
	debris:AddItem(panda, 300)

	-- Smoothing variable
	local currentGroundY = panda.Position.Y

	-- Movement loop
	task.spawn(function()
		while panda and panda.Parent do
			local target = followTag.Value
			if target and target:IsA("BasePart") and target.Parent then
				local followDistance = 3

				-- Hitung posisi goal horizontal
				local goalPos = target.Position - target.CFrame.LookVector * followDistance
				local dist = (goalPos - panda.Position).Magnitude

				if dist > 25 then
					-- Teleport kalau kejauhan
					panda.CFrame = target.CFrame * CFrame.new(0, 0, -followDistance)
					currentGroundY = panda.Position.Y
				else
					-- Raycast ke tanah (dengan filtering lebih baik)
					local rayParams = RaycastParams.new()
					rayParams.FilterDescendantsInstances = {panda}
					rayParams.FilterType = Enum.RaycastFilterType.Blacklist

					-- Raycast dari posisi target ke bawah
					local rayOrigin = Vector3.new(goalPos.X, target.Position.Y + 5, goalPos.Z)
					local rayDirection = Vector3.new(0, -15, 0)
					local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

					local targetY
					if rayResult then
						-- Ada tanah → Smooth transition ke ground
						local groundY = rayResult.Position.Y + (panda.Size.Y / 2) + 0.1
						currentGroundY = currentGroundY + (groundY - currentGroundY) * 0.3  -- ← SMOOTHING!
						targetY = currentGroundY
					else
						-- Ga ada tanah (di udara) → Ikutin target dengan smooth
						targetY = target.Position.Y
					end

					goalPos = Vector3.new(goalPos.X, targetY, goalPos.Z)
					bp.Position = goalPos

					-- Rotasi horizontal smooth
					local lookDirection = (target.Position - panda.Position) * Vector3.new(1, 0, 1)
					if lookDirection.Magnitude > 0.1 then
						bg.CFrame = CFrame.lookAt(panda.Position, panda.Position + lookDirection)
					end
				end
			else
				break
			end
			task.wait(0.03)  -- ← Update lebih sering biar smooth (dari 0.05 jadi 0.03)
		end
	end)

	return panda
end

-- Fungsi buat cleanup semua panda
function cleanupAllPandas()
	for _, v in pairs(pandas) do
		if v and v.Parent then
			v:Destroy()
		end
	end
	pandas = {}
end

-- Setup death listener untuk character
function setupDeathListener()
	-- Disconnect listener lama kalau ada
	if deathConnection then
		deathConnection:Disconnect()
		deathConnection = nil
	end

	local character = sp.Parent
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			deathConnection = humanoid.Died:Connect(function()
				print("Player died! Destroying all pandas...")
				cleanupAllPandas()
			end)
		end
	end
end

-- Saat tool digunakan
function onActivated()
	local character = sp.Parent
	local h = character and character:FindFirstChildOfClass("Humanoid")
	local t = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))

	if check and t and h and h.Health > 0 then
		check = false

		-- Setup death listener setiap kali spawn panda
		setupDeathListener()

		-- Bersihkan panda lama
		cleanupAllPandas()

		-- Spawn panda baru
		local lastpanda = t
		for i = 1, numberofpandas do
			lastpanda = createpanda(lastpanda)
		end

		local sound = sp:FindFirstChild("Sound")
		if sound then
			sound:Play()
		end

		task.wait(2)
		check = true
	end
end

sp.Activated:Connect(onActivated)

-- Setup listener pertama kali tool di-equip
sp.Equipped:Connect(function()
	setupDeathListener()
end)

-- Cleanup kalau tool dihapus dari game
sp.AncestryChanged:Connect(function(_, parent)
	if not parent then
		cleanupAllPandas()
		if deathConnection then
			deathConnection:Disconnect()
			deathConnection = nil
		end
	end
end)