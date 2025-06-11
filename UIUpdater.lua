-- UIUpdater.lua (FIXED VERSION)
-- Place this LocalScript in StarterGui

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

print("🔄 UIUpdater starting for " .. player.Name)

-- Import the NumberFormatter module
local NumberFormatter
local success, err = pcall(function()
	NumberFormatter = require(ReplicatedStorage:WaitForChild("NumberFormatter"))
end)

if not success then
	warn("❌ Failed to load NumberFormatter: " .. tostring(err))
	return
end

print("✅ NumberFormatter loaded successfully")

-- Wait for the player's leaderstats to be created
local leaderstats = player:WaitForChild("leaderstats", 30)
if not leaderstats then
	warn("❌ Leaderstats not found for " .. player.Name)
	return
end

local studs = leaderstats:WaitForChild("Studs", 10)
local coins = leaderstats:WaitForChild("Coins", 10)

if not studs or not coins then
	warn("❌ Studs or Coins not found in leaderstats")
	return
end

print("✅ Leaderstats found - Studs: " .. studs.Value .. ", Coins: " .. coins.Value)

-- Wait for the UI elements
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("ScreenGui", 10)

if not screenGui then
	warn("❌ ScreenGui not found")
	return
end

local coinFrame = screenGui:WaitForChild("CoinFrame", 5)
local studFrame = screenGui:WaitForChild("StudFrame", 5)

if not coinFrame or not studFrame then
	warn("❌ CoinFrame or StudFrame not found")
	return
end

local coinsLabel = coinFrame:WaitForChild("CoinsLabel", 5)
local studsLabel = studFrame:WaitForChild("StudsLabel", 5)

if not coinsLabel or not studsLabel then
	warn("❌ CoinsLabel or StudsLabel not found")
	return
end

print("✅ UI elements found successfully")

-- Function to update the UI with formatted numbers
local function updateUI()
	local formattedCoins = NumberFormatter.formatNumber(coins.Value)
	local formattedStuds = NumberFormatter.formatNumber(studs.Value)

	coinsLabel.Text = "Coins: " .. formattedCoins
	studsLabel.Text = "Studs: " .. formattedStuds

	print("🔄 UI Updated - Coins: " .. formattedCoins .. ", Studs: " .. formattedStuds)
end

-- Update UI immediately
updateUI()

-- Connect to value changes
local coinsConnection = coins.Changed:Connect(function(newValue)
	print("💰 Coins changed to: " .. newValue)
	updateUI()
end)

local studsConnection = studs.Changed:Connect(function(newValue)
	print("💎 Studs changed to: " .. newValue)
	updateUI()
end)

print("✅ UI Updater initialized successfully for " .. player.Name)

-- Clean up connections when player leaves
player.AncestryChanged:Connect(function()
	if not player.Parent then
		coinsConnection:Disconnect()
		studsConnection:Disconnect()
		print("🧹 UI Updater connections cleaned up")
	end
end)
