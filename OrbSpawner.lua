-- OrbSpawner.lua
-- Place this script in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local MAX_ORBS = 100
local SPAWN_INTERVAL = .5 -- seconds between spawn attempts

-- References
local grassPart = workspace:WaitForChild("GrassPart")
local orbPartOne = ReplicatedStorage:WaitForChild("OrbPartOne")
local orbPartFive = ReplicatedStorage:WaitForChild("OrbPartFive")
local orbPartTen = ReplicatedStorage:WaitForChild("OrbPartTen")

-- Orb types configuration
local orbTypes = {
	{template = orbPartOne, value = 1, weight = 50}, -- 50% chance
	{template = orbPartFive, value = 5, weight = 30}, -- 30% chance
	{template = orbPartTen, value = 10, weight = 20}   -- 20% chance
}

-- Orb tracking
local activeOrbs = {}
local lastSpawnTime = 0

-- Function to get random position on GrassPart
local function getRandomSpawnPosition()
	local size = grassPart.Size
	local position = grassPart.Position

	local randomX = position.X + math.random(-size.X/2, size.X/2)
	local randomZ = position.Z + math.random(-size.Z/2, size.Z/2)
	local spawnY = position.Y + (size.Y/2) + 3 -- Spawn 3 studs above the part

	return Vector3.new(randomX, spawnY, randomZ)
end

-- Function to select random orb type based on weights
local function selectRandomOrbType()
	local totalWeight = 0
	for _, orbType in ipairs(orbTypes) do
		totalWeight = totalWeight + orbType.weight
	end

	local randomValue = math.random(1, totalWeight)
	local currentWeight = 0

	for _, orbType in ipairs(orbTypes) do
		currentWeight = currentWeight + orbType.weight
		if randomValue <= currentWeight then
			return orbType
		end
	end

	-- Fallback to first orb type
	return orbTypes[1]
end

-- Function to spawn an orb
local function spawnOrb()
	if #activeOrbs >= MAX_ORBS then
		return -- Don't spawn if at limit
	end

	-- Select random orb type
	local selectedOrbType = selectRandomOrbType()

	-- Clone the selected orb
	local newOrb = selectedOrbType.template:Clone()
	newOrb.Position = getRandomSpawnPosition()
	newOrb.Parent = workspace

	-- Add to active orbs list with its value
	table.insert(activeOrbs, {orb = newOrb, value = selectedOrbType.value})

	-- Handle orb collection (when touched by player)
	local connection
	connection = newOrb.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = game.Players:GetPlayerFromCharacter(hit.Parent)
			if player and player.leaderstats and player.leaderstats.Studs then
				-- Get base stud value
				local baseStuds = selectedOrbType.value

				-- Get player's stud multiplier from shop system
				local studMultiplier = 1 -- Default multiplier
				if _G.ShopSystem and _G.ShopSystem.getPlayerStudMultiplier then
					studMultiplier = _G.ShopSystem.getPlayerStudMultiplier(player)
				end

				-- Calculate final stud value with multiplier
				local finalStuds = baseStuds * studMultiplier

				-- Give player studs with multiplier applied
				player.leaderstats.Studs.Value = player.leaderstats.Studs.Value + finalStuds

				-- Optional: Print collection info for debugging
				if studMultiplier > 1 then
					print(player.Name .. " collected " .. baseStuds .. " studs (x" .. studMultiplier .. " = " .. finalStuds .. " total)")
				end

				-- Remove orb from active list
				for i = #activeOrbs, 1, -1 do
					if activeOrbs[i].orb == newOrb then
						table.remove(activeOrbs, i)
						break
					end
				end

				-- Destroy orb
				connection:Disconnect()
				newOrb:Destroy()
			end
		end
	end)
end

-- Function to clean up destroyed orbs from the list
local function cleanupOrbsList()
	for i = #activeOrbs, 1, -1 do
		if not activeOrbs[i].orb or not activeOrbs[i].orb.Parent then
			table.remove(activeOrbs, i)
		end
	end
end

-- Main spawning loop
RunService.Heartbeat:Connect(function()
	local currentTime = tick()

	-- Clean up the orbs list periodically
	if currentTime - lastSpawnTime > 10 then -- Clean every 10 seconds
		cleanupOrbsList()
	end

	-- Check if it's time to spawn
	if currentTime - lastSpawnTime >= SPAWN_INTERVAL then
		spawnOrb()
		lastSpawnTime = currentTime
	end
end)

print("Orb Spawner initialized - Max orbs: " .. MAX_ORBS .. " with stud multiplier support")
