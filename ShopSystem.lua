-- ShopSystem.lua (FIXED VERSION - Resolves new player upgrade issues)
-- Place this script in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Import the NumberFormatter module
local NumberFormatter = require(ReplicatedStorage:WaitForChild("NumberFormatter"))

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
		maxLevel = 25, -- Maximum upgrade level
		partName = "DoubleStudPart" -- Name of the part in workspace
	}
}

-- Player data tracking
local playerUpgrades = {}
local playersInitialized = {} -- Track which players have been fully initialized

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
		print("DEBUG: Loaded upgrade data for " .. player.Name .. ":")
		for upgrade, level in pairs(data) do
			print("  " .. upgrade .. ": Level " .. level)
		end
	else
		playerUpgrades[player.UserId] = {}
		if not success then
			warn("Failed to load upgrade data for " .. player.Name)
		else
			print("New player " .. player.Name .. " - Starting with no upgrades")
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

	print("DEBUG: " .. player.Name .. " speed set to " .. newSpeed .. " (Level " .. currentLevel .. ")")
end

-- FIXED: Remove ALL existing GUIs for a specific player
local function clearPlayerShopGUIs(player)
	for powerupType, config in pairs(SHOP_CONFIG) do
		local part = workspace:FindFirstChild(config.partName)
		if part then
			local playerGui = part:FindFirstChild("ShopGUI_" .. player.Name .. "_" .. powerupType)
			if playerGui then
				print("DEBUG: Removing old GUI for " .. player.Name .. " - " .. powerupType)
				playerGui:Destroy()
			end
		end
	end
end

-- FIXED: Create individual BillboardGui for each player with better error handling
local function createPersonalShopGUI(player, powerupType)
	local config = SHOP_CONFIG[powerupType]
	local part = workspace:FindFirstChild(config.partName)
	if not part then 
		warn("DEBUG: Could not find part: " .. config.partName)
		return nil
	end

	-- Remove any existing GUI for this player first
	local existingGui = part:FindFirstChild("ShopGUI_" .. player.Name .. "_" .. powerupType)
	if existingGui then
		existingGui:Destroy()
		wait(0.1) -- Small delay to ensure cleanup
	end

	local success, gui = pcall(function()
		-- Create a BillboardGui that shows this player's personal price
		local billboardGui = Instance.new("BillboardGui")
		billboardGui.Name = "ShopGUI_" .. player.Name .. "_" .. powerupType
		billboardGui.Size = UDim2.new(4, 0, 2, 0)
		billboardGui.StudsOffset = Vector3.new(0, 3, 0)
		billboardGui.Parent = part

		-- Create background frame
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		frame.BackgroundTransparency = 0.3
		frame.BorderSizePixel = 0
		frame.Parent = billboardGui

		-- Add corner rounding
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = frame

		-- Create title label
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "Title"
		titleLabel.Size = UDim2.new(0.9, 0, 0.4, 0)
		titleLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
		titleLabel.TextScaled = true
		titleLabel.Font = Enum.Font.SourceSansBold
		titleLabel.Text = powerupType .. " Upgrade"
		titleLabel.Parent = frame

		-- Create price label
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "Price"
		priceLabel.Size = UDim2.new(0.9, 0, 0.4, 0)
		priceLabel.Position = UDim2.new(0.05, 0, 0.5, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		priceLabel.TextScaled = true
		priceLabel.Font = Enum.Font.SourceSansBold
		priceLabel.Text = "Loading..."
		priceLabel.Parent = frame

		return billboardGui
	end)

	if success and gui then
		print("DEBUG: Successfully created GUI for " .. player.Name .. " - " .. powerupType)
		return gui
	else
		warn("DEBUG: Failed to create GUI for " .. player.Name .. " - " .. powerupType .. ": " .. tostring(gui))
		return nil
	end
end

-- FIXED: Update price for specific player with better validation
local function updatePlayerShopPrice(player, powerupType)
	-- Validate player still exists
	if not player or not player.Parent then
		return
	end

	local config = SHOP_CONFIG[powerupType]
	if not config then return end

	local part = workspace:FindFirstChild(config.partName)
	if not part then 
		warn("DEBUG: Part not found: " .. config.partName)
		return 
	end

	-- Find this player's personal GUI
	local playerGui = part:FindFirstChild("ShopGUI_" .. player.Name .. "_" .. powerupType)
	if not playerGui then
		print("DEBUG: GUI not found for " .. player.Name .. " - " .. powerupType .. ", creating new one")
		playerGui = createPersonalShopGUI(player, powerupType)
		if not playerGui then
			warn("DEBUG: Failed to create GUI for " .. player.Name .. " - " .. powerupType)
			return
		end
	end

	local frame = playerGui:FindFirstChild("Frame")
	if not frame then 
		warn("DEBUG: Frame not found in GUI for " .. player.Name .. " - " .. powerupType)
		return 
	end

	local priceLabel = frame:FindFirstChild("Price")
	if not priceLabel then 
		warn("DEBUG: Price label not found in GUI for " .. player.Name .. " - " .. powerupType)
		return 
	end

	local playerLevel = getPlayerLevel(player, powerupType)

	print("DEBUG: Updating price for " .. player.Name .. " - " .. powerupType .. " (Level " .. playerLevel .. ")")

	-- Check if at max level
	if playerLevel >= config.maxLevel then
		priceLabel.Text = "MAX LEVEL"
		priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
		print("DEBUG: " .. player.Name .. " is at max level for " .. powerupType)
	else
		-- Calculate next upgrade cost for this specific player
		local nextCost = calculateCost(powerupType, playerLevel)
		-- FORMAT THE PRICE HERE!
		priceLabel.Text = NumberFormatter.formatNumber(nextCost) .. " Coins"
		priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White color
		print("DEBUG: " .. player.Name .. " next " .. powerupType .. " cost: " .. NumberFormatter.formatNumber(nextCost))
	end
end

-- Function to handle powerup purchase
local function purchasePowerup(player, powerupType)
	-- Validate player is properly initialized
	if not playersInitialized[player.UserId] then
		print("DEBUG: " .. player.Name .. " not fully initialized yet, attempting purchase...")
		-- Try to initialize them quickly
		initializePlayerShop(player)
		wait(0.5) -- Give it a moment
	end

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

	print("DEBUG: " .. player.Name .. " attempting to buy " .. powerupType .. " (Current Level: " .. currentLevel .. ")")

	-- Check if at max level
	if currentLevel >= config.maxLevel then
		print("DEBUG: " .. player.Name .. " has reached maximum level for " .. powerupType)
		return false
	end

	local cost = calculateCost(powerupType, currentLevel)
	local playerCoins = player.leaderstats.Coins.Value

	print("DEBUG: Cost: " .. NumberFormatter.formatNumber(cost) .. ", Player has: " .. NumberFormatter.formatNumber(playerCoins))

	-- Check if player has enough coins
	if playerCoins < cost then
		print("DEBUG: " .. player.Name .. " doesn't have enough coins. Need: " .. NumberFormatter.formatNumber(cost) .. ", Has: " .. NumberFormatter.formatNumber(playerCoins))
		return false
	end

	-- Deduct coins
	player.leaderstats.Coins.Value = player.leaderstats.Coins.Value - cost

	-- Increase level
	local newLevel = currentLevel + 1
	setPlayerLevel(player, powerupType, newLevel)

	print("DEBUG: " .. player.Name .. " upgraded " .. powerupType .. " to level " .. newLevel)

	-- Apply the upgrade
	if powerupType == "Speed" then
		applySpeedUpgrade(player)
	elseif powerupType == "DoubleStud" then
		print("DEBUG: " .. player.Name .. " now has " .. getPlayerStudMultiplier(player) .. "x stud multiplier!")
	end

	-- Update this player's shop price display
	updatePlayerShopPrice(player, powerupType)

	-- Save the upgrade data immediately
	savePlayerUpgrades(player)

	return true
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
				purchasePowerup(player, powerupType)
			end
		end
	end)

	print("Shop part connected: " .. config.partName)
end

-- NEW: Separate function to initialize player shop data and GUIs
local function initializePlayerShop(player)
	print("DEBUG: Initializing shop for " .. player.Name)
	
	-- Load player upgrade data from DataStore
	loadPlayerUpgrades(player)
	
	-- Clear any existing GUIs for this player
	clearPlayerShopGUIs(player)
	
	-- Create personal shop GUIs for each powerup
	for powerupType, _ in pairs(SHOP_CONFIG) do
		local gui = createPersonalShopGUI(player, powerupType)
		if gui then
			-- Small delay then update the price
			spawn(function()
				wait(0.2)
				updatePlayerShopPrice(player, powerupType)
			end)
		else
			warn("DEBUG: Failed to create GUI for " .. player.Name .. " - " .. powerupType)
		end
	end
	
	-- Mark player as initialized
	playersInitialized[player.UserId] = true
	print("DEBUG: Shop initialization completed for " .. player.Name)
end

-- FIXED: Function to initialize player upgrades when they join
local function onPlayerAdded(player)
	print("DEBUG: Player " .. player.Name .. " joined, waiting for leaderstats...")
	
	-- Wait for leaderstats to be created
	local leaderstats = player:WaitForChild("leaderstats", 30)
	if not leaderstats then
		warn("DEBUG: Leaderstats timeout for " .. player.Name)
		return
	end
	
	-- Wait for Coins to be created
	local coins = leaderstats:WaitForChild("Coins", 10)
	if not coins then
		warn("DEBUG: Coins timeout for " .. player.Name)
		return
	end
	
	print("DEBUG: Leaderstats ready for " .. player.Name)
	
	-- Initialize shop after a short delay
	spawn(function()
		wait(2) -- Give time for everything to settle
		initializePlayerShop(player)
	end)

	-- Handle character spawning
	player.CharacterAdded:Connect(function(character)
		wait(1) -- Small delay to ensure character is fully loaded
		if playersInitialized[player.UserId] then
			applySpeedUpgrade(player)
			-- Refresh shop prices
			for powerupType, _ in pairs(SHOP_CONFIG) do
				updatePlayerShopPrice(player, powerupType)
			end
		else
			-- If not initialized, do it now
			initializePlayerShop(player)
			wait(1)
			applySpeedUpgrade(player)
		end
	end)

	-- If character already exists
	if player.Character then
		spawn(function()
			wait(3) -- Wait for shop initialization
			if playersInitialized[player.UserId] then
				applySpeedUpgrade(player)
			end
		end)
	end
end

-- Function to save player data when they leave
local function onPlayerRemoving(player)
	print("DEBUG: Player " .. player.Name .. " leaving, cleaning up...")
	
	-- Clean up personal shop GUIs
	clearPlayerShopGUIs(player)

	-- Save upgrade data to DataStore
	savePlayerUpgrades(player)

	-- Clean up memory
	playerUpgrades[player.UserId] = nil
	playersInitialized[player.UserId] = nil
	
	print("DEBUG: Cleanup completed for " .. player.Name)
end

-- Initialize the shop system
local function initializeShop()
	print("DEBUG: Initializing Shop System...")
	
	-- Setup part connections for all powerups
	for powerupType, config in pairs(SHOP_CONFIG) do
		setupPartConnection(powerupType)
	end

	-- Connect player events
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Handle players already in game
	for _, player in pairs(Players:GetPlayers()) do
		spawn(function()
			onPlayerAdded(player)
		end)
	end

	print("DEBUG: Shop System initialized with formatted prices!")
end

-- Auto-save upgrades every 5 minutes
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
	savePlayerUpgrades = savePlayerUpgrades,
	getPlayerStudMultiplier = getPlayerStudMultiplier,
	-- NEW: Manual refresh function for debugging
	refreshPlayerShop = function(player)
		if player and player.Parent then
			initializePlayerShop(player)
		end
	end
}

-- Debug command to refresh all shops
_G.RefreshAllShops = function()
	for _, player in pairs(Players:GetPlayers()) do
		if player.leaderstats then
			initializePlayerShop(player)
		end
	end
	print("DEBUG: Refreshed all player shops")
end

print("DEBUG: Shop System loaded successfully!")
print("DEBUG: Use _G.RefreshAllShops() to manually refresh all shops if needed")
