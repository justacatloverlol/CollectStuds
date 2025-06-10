-- ===========================================
-- CLIENT SCRIPT: ClientOrbSpawner.lua  
-- Place this LocalScript in StarterPlayerScripts
-- ===========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Wait for RemoteEvents
local orbRemotes = ReplicatedStorage:WaitForChild("OrbRemotes")
local collectOrbRemote = orbRemotes:WaitForChild("CollectOrb")
local getMultiplierRemote = orbRemotes:WaitForChild("GetMultiplier")

-- Configuration
local MAX_ORBS = 100
local SPAWN_INTERVAL = 0.5 -- seconds between spawn attempts

-- References (wait for them to exist)
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

-- Client-side orb tracking
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

-- Function to spawn an orb (client-side only)
local function spawnOrb()
	if #activeOrbs >= MAX_ORBS then
		return -- Don't spawn if at limit
	end

	-- Only spawn if player has a character
	if not player.Character then
		return
	end

	-- Select random orb type
	local selectedOrbType = selectRandomOrbType()

	-- Clone the selected orb
	local newOrb = selectedOrbType.template:Clone()
	newOrb.Position = getRandomSpawnPosition()
	newOrb.Parent = workspace

	-- Add to active orbs list with its value
	table.insert(activeOrbs, {orb = newOrb, value = selectedOrbType.value})

	-- Handle orb collection (only for this client's character)
	local connection
	connection = newOrb.Touched:Connect(function(hit)
		-- Only collect if touched by this player's character
		if hit.Parent == player.Character then
			local humanoid = hit.Parent:FindFirstChild("Humanoid")
			if humanoid then
				-- Tell server we collected an orb
				collectOrbRemote:FireServer(selectedOrbType.value)

				-- Remove orb from active list
				for i = #activeOrbs, 1, -1 do
					if activeOrbs[i].orb == newOrb then
						table.remove(activeOrbs, i)
						break
					end
				end

				-- Destroy orb (client-side)
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

-- Clean up orbs when character is removed (player dies/resets)
player.CharacterRemoving:Connect(function()
	-- Destroy all active orbs
	for _, orbData in ipairs(activeOrbs) do
		if orbData.orb and orbData.orb.Parent then
			orbData.orb:Destroy()
		end
	end
	activeOrbs = {}
end)

print("Client-side Orb Spawner initialized for " .. player.Name .. " - Max orbs: " .. MAX_ORBS)
