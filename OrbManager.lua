-- ===========================================
-- SERVER SCRIPT: OrbManager.lua
-- Place this in ServerScriptService
-- ===========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvents for client-server communication
local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "OrbRemotes"
remoteEvents.Parent = ReplicatedStorage

local collectOrbRemote = Instance.new("RemoteEvent")
collectOrbRemote.Name = "CollectOrb"
collectOrbRemote.Parent = remoteEvents

local getMultiplierRemote = Instance.new("RemoteFunction")
getMultiplierRemote.Name = "GetMultiplier"
getMultiplierRemote.Parent = remoteEvents

-- Function to get player's stud multiplier
getMultiplierRemote.OnServerInvoke = function(player)
	local studMultiplier = 1 -- Default multiplier
	if _G.ShopSystem and _G.ShopSystem.getPlayerStudMultiplier then
		studMultiplier = _G.ShopSystem.getPlayerStudMultiplier(player)
	end
	return studMultiplier
end

-- Handle orb collection from clients
collectOrbRemote.OnServerEvent:Connect(function(player, orbValue)
	-- Validate the player and orb value
	if not player or not player.leaderstats or not player.leaderstats.Studs then
		return
	end

	-- Validate orb value (only allow valid orb values)
	local validValues = {1, 5, 10}
	local isValid = false
	for _, validValue in ipairs(validValues) do
		if orbValue == validValue then
			isValid = true
			break
		end
	end

	if not isValid then
		warn("Invalid orb value from " .. player.Name .. ": " .. tostring(orbValue))
		return
	end

	-- Get player's stud multiplier
	local studMultiplier = 1
	if _G.ShopSystem and _G.ShopSystem.getPlayerStudMultiplier then
		studMultiplier = _G.ShopSystem.getPlayerStudMultiplier(player)
	end

	-- Calculate final stud value with multiplier
	local finalStuds = orbValue * studMultiplier

	-- Give player studs
	player.leaderstats.Studs.Value = player.leaderstats.Studs.Value + finalStuds

	-- Optional: Print collection info for debugging
	if studMultiplier > 1 then
		print(player.Name .. " collected " .. orbValue .. " studs (x" .. studMultiplier .. " = " .. finalStuds .. " total)")
	end
end)

print("Server-side Orb Manager initialized")
