-- ShopSystem.lua (DEBUG VERSION)
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
		maxLevel = 25, -- Maximum upgrade level
		partName = "DoubleStudPart" -- Name of the part in workspace
	}
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

-- FIXED: Remove ALL existing GUIs first, then create fresh ones
local function clearAllShopGUIs(part)
	-- Remove all BillboardGuis and SurfaceGuis
	for _, child in pairs(part:GetChildren()) do
		if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
			print("DEBUG: Removing old GUI: " .. child.Name)
			child:Destroy()
		end
	end
end

-- Create individual BillboardGui for each player (visible to all but shows personal price)
local function createPersonalShopGUI(player, powerupType)
	local config = SHOP_CONFIG[powerupType]
	local part = workspace:FindFirstChild(config.partName)
	if not part then 
		warn("DEBUG: Could not find part: " .. config.partName)
		return 
	end

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
	priceLabel.Parent = frame

	print("DEBUG: Created GUI for " .. player.Name .. " - " .. powerupType)
	return priceLabel
end

-- Update price for specific player
local function updatePlayerShopPrice(player, powerupType)
	local config = SHOP_CONFIG[powerupType]
	if not config then return end

	local part = workspace:FindFirstChild(config.partName)
	if not part then return end

	-- Find this player's personal GUI
	local playerGui = part:FindFirstChild("ShopGUI_" .. player.Name .. "_" .. powerupType)
	if not playerGui then
		print("DEBUG: GUI not found for " .. player.Name .. " - " .. powerupType .. ", creating new one")
		createPersonalShopGUI(player, powerupType)
		playerGui = part:FindFirstChild("ShopGUI_" .. player.Name .. "_" .. powerupType)
	end

	if not playerGui then 
		warn("DEBUG: Still couldn't create GUI for " .. player.Name .. " - " .. powerupType)
		return 
	end

	local frame = playerGui:FindFirstChild("Frame")
	if not frame then return end

	local priceLabel = frame:FindFirstChild("Price")
	if not priceLabel then return end

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
		priceLabel.Text = nextCost .. " Coins"
		priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White color
		print("DEBUG: " .. player.Name .. " next " .. powerupType .. " cost: " .. nextCost)
	end
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

	print("DEBUG: " .. player.Name .. " attempting to buy " .. powerupType .. " (Current Level: " .. currentLevel .. ")")

	-- Check if at max level
	if currentLevel >= config.maxLevel then
		print("DEBUG: " .. player.Name .. " has reached maximum level for " .. powerupType)
		return false
	end

	local cost = calculateCost(powerupType, currentLevel)
	local playerCoins = player.leaderstats.Coins.Value

	print("DEBUG: Cost: " .. cost .. ", Player has: " .. playerCoins)

	-- Check if player has enough coins
	if playerCoins < cost then
		print("DEBUG: " .. player.Name .. " doesn't have enough coins. Need: " .. cost .. ", Has: " .. playerCoins)
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

	-- Clear any existing GUIs on this part
	clearAllShopGUIs(part)

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

-- Function to initialize player upgrades when they join
local function onPlayerAdded(player)
	-- Wait for leaderstats to be created
	player:WaitForChild("leaderstats")

	-- Load player upgrade data from DataStore
	loadPlayerUpgrades(player)

	-- Wait a moment for data to load, then create personal shop GUIs
	wait(1)
	for powerupType, _ in pairs(SHOP_CONFIG) do
		createPersonalShopGUI(player, powerupType)
		updatePlayerShopPrice(player, powerupType)
	end

	-- Wait for character to spawn, then apply upgrades
	player.CharacterAdded:Connect(function(character)
		wait(1) -- Small delay to ensure character is fully loaded
		applySpeedUpgrade(player)
		-- Update shop prices when character spawns
		for powerupType, _ in pairs(SHOP_CONFIG) do
			updatePlayerShopPrice(player, powerupType)
		end
	end)

	-- If character already exists
	if player.Character then
		wait(1)
		applySpeedUpgrade(player)
		-- Update shop prices for existing character
		for powerupType, _ in pairs(SHOP_CONFIG) do
			updatePlayerShopPrice(player, powerupType)
		end
	end
end

-- Function to save player data when they leave
local function onPlayerRemoving(player)
	-- Clean up personal shop GUIs
	for powerupType, config in pairs(SHOP_CONFIG) do
		local part = workspace:FindFirstChild(config.partName)
		if part then
			local playerGui = part:FindFirstChild("ShopGUI_" .. player.Name .. "_" .. powerupType)
			if playerGui then
				playerGui:Destroy()
			end
		end
	end

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
	end

	-- Connect player events
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Handle players already in game
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	print("DEBUG: Shop System initialized with individual player GUIs!")
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
	getPlayerStudMultiplier = getPlayerStudMultiplier
}
