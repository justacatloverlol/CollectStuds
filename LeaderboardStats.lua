-- LeaderboardStats.lua
-- Place this script in ServerScriptService

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Create DataStore
local playerDataStore = DataStoreService:GetDataStore("PlayerData")

local function onPlayerAdded(player)
	-- Create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Create Studs stat
	local studs = Instance.new("IntValue")
	studs.Name = "Studs"
	studs.Parent = leaderstats

	-- Create Coins stat (cash)
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats

	-- Load player data
	local success, data = pcall(function()
		return playerDataStore:GetAsync(player.UserId)
	end)

	if success and data then
		studs.Value = data.Studs or 0
		coins.Value = data.Coins or 0
		print("Loaded data for " .. player.Name .. " - Studs: " .. studs.Value .. ", Coins: " .. coins.Value)
	else
		studs.Value = 0
		coins.Value = 0
		if not success then
			warn("Failed to load data for " .. player.Name)
		else
			print("New player " .. player.Name .. " - Starting with 0 studs and coins")
		end
	end

	-- Optional: Add value change listeners for debugging
	studs.Changed:Connect(function(newValue)
		print(player.Name .. " studs changed to: " .. newValue)
	end)

	coins.Changed:Connect(function(newValue)
		print(player.Name .. " coins changed to: " .. newValue)
	end)
end

local function onPlayerRemoving(player)
	-- Save player data
	if player.leaderstats then
		local success = pcall(function()
			local dataToSave = {
				Studs = player.leaderstats.Studs.Value,
				Coins = player.leaderstats.Coins.Value
			}
			playerDataStore:SetAsync(player.UserId, dataToSave)
		end)

		if success then
			print("Saved data for " .. player.Name)
		else
			warn("Failed to save data for " .. player.Name)
		end
	end
end

-- Connect the functions
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in the game (for testing)
for _, player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Auto-save every 5 minutes
spawn(function()
	while true do
		wait(300) -- 5 minutes
		for _, player in pairs(Players:GetPlayers()) do
			if player.leaderstats then
				local success = pcall(function()
					local dataToSave = {
						Studs = player.leaderstats.Studs.Value,
						Coins = player.leaderstats.Coins.Value
					}
					playerDataStore:SetAsync(player.UserId, dataToSave)
				end)

				if success then
					print("Auto-saved data for " .. player.Name)
				else
					warn("Auto-save failed for " .. player.Name)
				end
			end
		end
		print("Auto-save cycle completed")
	end
end)
