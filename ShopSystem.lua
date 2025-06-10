-- ShopSystem.lua
-- Place this script in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Create DataStore for shop upgrades
local shopDataStore = DataStoreService:GetDataStore("ShopUpgrades")

-- Shop Configuration
local SHOP_CONFIG = {
	Speed = {
		baseCost = 100,
		costMultiplier = 1.5, -- Each upgrade costs 50% more
		baseIncrement = 2, -- Base speed increase per level
		maxLevel = 40, -- Maximum upgrade level
		partName = "SpeedPart" -- Name of the part in workspace
	},
	DoubleStud = {
		baseCost = 200,
		costMultiplier = 2.0, -- Each upgrade costs 100% more (doubles)
		baseMultiplier = 2, -- 2x multiplier per level
		maxLevel = 25, -- Maximum upgrade level (2^10 = 1024x)
		partName = "DoubleStudPart" -- Name of the part in workspace
	}
	-- Add more powerups here later:
	-- Jump = {
	--     baseCost = 150,
	--     costMultiplier = 1.4,
	--     baseIncrement = 5,
	--     maxLevel = 30,
	--     partName = "JumpPart"
	-- }
}

-- Player data tracking
local playerUpgrades = {}

-- Function to calculate cost for next level
local function calculateCost(powerupType, currentLevel)
	local config = SHOP_CONFIG[powerupType]
	if not config then return 0 end

	-- Formula: baseCost * (multiplier ^ currentLevel)
	return math.floor(config.baseCost * (config.costMultiplier ^ currentLevel))
end

-- Function to get player's current level for a powerup
local function getPlayerLevel(player, powerupType)
	if not playerUpgrades[player.UserId] then
		playerUpgrades[player.UserId] = {}
	end

	return playerUpgrades[player.UserId][powerupType] or 0
end

-- Function to set player's level for a powerup
local function setPlayerLevel(player, powerupType, level)
	if not playerUpgrades[player.UserId] then
		playerUpgrades[player.UserId] = {}
	end

	playerUpgrades[player.UserId][powerupType] = level
end

-- Function to load player upgrade data from DataStore
local function loadPlayerUpgrades(player)
	local success, data = pcall(function()
		return shopDataStore:GetAsync(player.UserId)
	end)

	if success and data then
		playerUpgrades[player.UserId] = data
		print("Loaded upgrade data for " .. player.Name)
	else
		playerUpgrades[player.UserId] = {}
		if not success then
			warn("Failed to load upgrade data for " .. player.Name)
		end
	end
end

-- Function to save player upgrade data to DataStore
local function savePlayerUpgrades(player)
	if not playerUpgrades[player.UserId] then
		return
	end

	local success = pcall(function()
		shopDataStore:SetAsync(player.UserId, playerUpgrades[player.UserId])
	end)

	if success then
		print("Saved upgrade data for " .. player.Name)
	else
		warn("Failed to save upgrade data for " .. player.Name)
	end
end

-- Function to get player's stud multiplier
local function getPlayerStudMultiplier(player)
	local doubleStudLevel = getPlayerLevel(player, "DoubleStud")
	-- Calculate multiplier: 2^level (1x, 2x, 4x, 8x, 16x, etc.)
	return math.pow(2, doubleStudLevel)
end

-- Function to apply speed upgrade to player
local function applySpeedUpgrade(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local currentLevel = getPlayerLevel(player, "Speed")
	local config = SHOP_CONFIG.Speed

	-- Calculate new speed: 16 (default) + (level * baseIncrement)
	local newSpeed = 16 + (currentLevel * config.baseIncrement)
	humanoid.WalkSpeed = newSpeed

	print(player.Name .. " speed set to " .. newSpeed .. " (Level " .. currentLevel .. ")")
end

-- Function to handle powerup purchase
local function purchasePowerup(player, powerupType)
	local config = SHOP_CONFIG[powerupType]
	if not config then
		warn("Invalid powerup type: " .. powerupType)
		return false
	end

	-- Check if player has leaderstats
	if not player.leaderstats or not player.leaderstats.Coins then
		warn("Player " .. player.Name .. " doesn't have leaderstats")
		return false
	end

	local currentLevel = getPlayerLevel(player, powerupType)

	-- Check if at max level
	if currentLevel >= config.maxLevel then
		print(player.Name .. " has reached maximum level for " .. powerupType)
		return false
	end

	local cost = calculateCost(powerupType, currentLevel)
	local playerCoins = player.leaderstats.Coins.Value

	-- Check if player has enough coins
	if playerCoins < cost then
		print(player.Name .. " doesn't have enough coins. Need: " .. cost .. ", Has: " .. playerCoins)
		return false
	end

	-- Deduct coins
	player.leaderstats.Coins.Value = player.leaderstats.Coins.Value - cost

	-- Increase level
	local newLevel = currentLevel + 1
	setPlayerLevel(player, powerupType, newLevel)

	-- Apply the upgrade
	if powerupType == "Speed" then
		applySpeedUpgrade(player)
	elseif powerupType == "DoubleStud" then
		-- DoubleStud upgrade doesn't need to apply anything immediately
		-- The multiplier is calculated when studs are collected
		print(player.Name .. " now has " .. getPlayerStudMultiplier(player) .. "x stud multiplier!")
	end

	-- Update billboard GUI
	updateBillboardPrice(powerupType, newLevel)

	-- Save the upgrade data immediately
	savePlayerUpgrades(player)

	print(player.Name .. " purchased " .. powerupType .. " upgrade! Level: " .. newLevel .. " Cost: " .. cost)
	return true
end

-- Function to update billboard GUI price for a specific player
function updateBillboardPriceForPlayer(player, powerupType)
	local config = SHOP_CONFIG[powerupType]
	if not config then return end

	local part = workspace:FindFirstChild(config.partName)
	if not part then return end

	local billboardGui = part:FindFirstChild("BillboardGui")
	if not billboardGui then return end

	local textLabel = billboardGui:FindFirstChild("Price")
	if not textLabel then return end

	local playerLevel = getPlayerLevel(player, powerupType)

	-- Check if at max level
	if playerLevel >= config.maxLevel then
		textLabel.Text = "MAX LEVEL"
		textLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
	else
		-- Calculate next upgrade cost
		local nextCost = calculateCost(powerupType, playerLevel)
		textLabel.Text = tostring(nextCost)
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White color
	end
end

-- Function to update billboard GUI price (legacy function for compatibility)
function updateBillboardPrice(powerupType, playerLevel)
	local config = SHOP_CONFIG[powerupType]
	if not config then return end

	local part = workspace:FindFirstChild(config.partName)
	if not part then return end

	local billboardGui = part:FindFirstChild("BillboardGui")
	if not billboardGui then return end

	local textLabel = billboardGui:FindFirstChild("Price")
	if not textLabel then return end

	-- Calculate next upgrade cost
	local nextCost = calculateCost(powerupType, playerLevel)

	-- Check if at max level
	if playerLevel >= config.maxLevel then
		textLabel.Text = "MAX LEVEL"
		textLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
	else
		textLabel.Text = tostring(nextCost)
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White color
	end
end

-- Function to setup part connections
local function setupPartConnection(powerupType)
	local config = SHOP_CONFIG[powerupType]
	local part = workspace:FindFirstChild(config.partName)

	if not part then
		warn("Could not find part: " .. config.partName)
		return
	end

	-- Connect touch event
	part.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character:FindFirstChild("Humanoid")

		if humanoid then
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				-- Update billboard for this player before purchase attempt
				updateBillboardPriceForPlayer(player, powerupType)
				purchasePowerup(player, powerupType)
			end
		end
	end)

	print("Shop part connected: " .. config.partName)
end

-- Function to initialize player upgrades when they join
local function onPlayerAdded(player)
	-- Wait for leaderstats to be created
	player:WaitForChild("leaderstats")

	-- Load player upgrade data from DataStore
	loadPlayerUpgrades(player)

	-- Wait a moment for data to load, then update billboard prices
	wait(0.5)
	for powerupType, _ in pairs(SHOP_CONFIG) do
		updateBillboardPriceForPlayer(player, powerupType)
	end

	-- Wait for character to spawn, then apply upgrades
	player.CharacterAdded:Connect(function(character)
		wait(1) -- Small delay to ensure character is fully loaded
		applySpeedUpgrade(player)
		-- Update billboard when character spawns
		for powerupType, _ in pairs(SHOP_CONFIG) do
			updateBillboardPriceForPlayer(player, powerupType)
		end
	end)

	-- If character already exists
	if player.Character then
		wait(1)
		applySpeedUpgrade(player)
		-- Update billboard for existing character
		for powerupType, _ in pairs(SHOP_CONFIG) do
			updateBillboardPriceForPlayer(player, powerupType)
		end
	end
end

-- Function to save player data when they leave
local function onPlayerRemoving(player)
	-- Save upgrade data to DataStore
	savePlayerUpgrades(player)

	-- Clean up memory
	playerUpgrades[player.UserId] = nil
end

-- Initialize the shop system
local function initializeShop()
	-- Setup part connections for all powerups
	for powerupType, config in pairs(SHOP_CONFIG) do
		setupPartConnection(powerupType)
		-- Initialize billboard with base price (will be updated when players join)
		updateBillboardPrice(powerupType, 0)
	end

	-- Connect player events
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Handle players already in game
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	print("Shop System initialized!")
end

-- Auto-save upgrades every 5 minutes (optional safety measure)
spawn(function()
	while true do
		wait(300) -- 5 minutes
		for _, player in pairs(Players:GetPlayers()) do
			if playerUpgrades[player.UserId] then
				savePlayerUpgrades(player)
			end
		end
		print("Auto-saved all player upgrades")
	end
end)

-- Start the shop system
initializeShop()

-- Public functions for other scripts to use
_G.ShopSystem = {
	getPlayerLevel = getPlayerLevel,
	calculateCost = calculateCost,
	purchasePowerup = purchasePowerup,
	savePlayerUpgrades = savePlayerUpgrades, -- Added for manual saving if needed
	getPlayerStudMultiplier = getPlayerStudMultiplier -- Added for orb collection
}
