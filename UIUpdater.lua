-- UIUpdater.lua (UPDATED VERSION)
-- Place this LocalScript in StarterGui (NOT ServerScriptService)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Import the NumberFormatter module
local NumberFormatter = ReplicatedStorage:WaitForChild("NumberFormatter")

-- Wait for the player's leaderstats to be created
local leaderstats = player:WaitForChild("leaderstats")
local studs = leaderstats:WaitForChild("Studs")
local coins = leaderstats:WaitForChild("Coins")

-- Wait for the UI elements
local screenGui = script.Parent -- The script is already inside ScreenGui
local coinFrame = screenGui:WaitForChild("CoinFrame")
local studFrame = screenGui:WaitForChild("StudFrame")
local coinsLabel = coinFrame:WaitForChild("CoinsLabel")
local studsLabel = studFrame:WaitForChild("StudsLabel")

-- Function to update the UI with formatted numbers
local function updateUI()
	coinsLabel.Text = "Coins: " .. NumberFormatter.formatNumber(coins.Value)
	studsLabel.Text = "Studs: " .. NumberFormatter.formatNumber(studs.Value)
end

-- Update UI immediately
updateUI()

-- Connect to value changes
coins.Changed:Connect(updateUI)
studs.Changed:Connect(updateUI)

print("UI Updater initialized for " .. player.Name .. " with number formatting!")

-- Optional: Test the formatter (remove this in production)
-- NumberFormatter.test()
