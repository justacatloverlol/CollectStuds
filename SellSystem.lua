-- SellSystem.lua
-- Place this script in ServerScriptService

local Players = game:GetService("Players")

-- Configuration
local SELL_RATE = 10 -- 1 stud = 10 coins
local SELL_COOLDOWN = 1 -- Cooldown in seconds to prevent spam

-- Reference to the sell part
local sellPart = workspace:WaitForChild("Sell") -- Change "Sell" to your part's name

-- Track player cooldowns
local playerCooldowns = {}

-- Function to sell studs
local function sellStuds(player)
	-- Check if player has leaderstats
	if not player.leaderstats then
		return
	end

	local studs = player.leaderstats.Studs
	local coins = player.leaderstats.Coins

	-- Check if player has studs to sell
	if studs.Value <= 0 then
		return -- No studs to sell
	end

	-- Check cooldown
	local currentTime = tick()
	if playerCooldowns[player.UserId] and currentTime - playerCooldowns[player.UserId] < SELL_COOLDOWN then
		return -- Still on cooldown
	end

	-- Calculate coins to give
	local coinsToGive = studs.Value * SELL_RATE

	-- Perform the transaction
	coins.Value = coins.Value + coinsToGive
	studs.Value = 0 -- Reset studs to 0

	-- Set cooldown
	playerCooldowns[player.UserId] = currentTime

	-- Optional: Print transaction info (remove in production)
	print(player.Name .. " sold studs for " .. coinsToGive .. " coins!")
end

-- Connect to sell part
sellPart.Touched:Connect(function(hit)
	-- Check if a player touched it
	local character = hit.Parent
	local humanoid = character:FindFirstChild("Humanoid")

	if humanoid then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			sellStuds(player)
		end
	end
end)

-- Clean up cooldowns when players leave
Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player.UserId] = nil
end)

print("Sell System initialized - Rate: 1 Stud = " .. SELL_RATE .. " Coins")
