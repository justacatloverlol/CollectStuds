-- LeaderboardSystem.lua (FIXED VERSION - ScrollFrame Error Resolution)
-- Place this script in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Import the NumberFormatter module with enhanced debugging
local NumberFormatterModule = ReplicatedStorage:WaitForChild("NumberFormatter")
local NumberFormatter

-- Enhanced debugging for NumberFormatter
print("🔍 NumberFormatter module debugging:")
print("   Module object type: " .. type(NumberFormatterModule))
print("   Module class: " .. NumberFormatterModule.ClassName)

-- Try to require the module
local success, result = pcall(function()
	return require(NumberFormatterModule)
end)

if success then
	NumberFormatter = result
	print("✅ Successfully required NumberFormatter module")
	print("   Result type: " .. type(NumberFormatter))

	if type(NumberFormatter) == "table" then
		print("   Available functions/properties:")
		for key, value in pairs(NumberFormatter) do
			print("      - " .. key .. " (" .. type(value) .. ")")
		end

		-- Test the formatNumber function specifically
		if NumberFormatter.formatNumber then
			print("✅ formatNumber function found!")
			local testSuccess, testResult = pcall(function()
				return NumberFormatter.formatNumber(1234567)
			end)
			if testSuccess then
				print("✅ formatNumber test successful: " .. testResult)
			else
				print("❌ formatNumber test failed: " .. tostring(testResult))
			end
		else
			print("❌ formatNumber function NOT found in module!")
		end
	else
		print("❌ Required module is not a table!")
	end
else
	print("❌ Failed to require NumberFormatter module: " .. tostring(result))
	NumberFormatter = nil
end

-- Configuration
local LEADERBOARD_SIZE = 10 -- Show top 10 players
local UPDATE_INTERVAL = 300 -- 5 seconds for testing (change to 300 for 5 minutes)
local LEADERBOARD_PART_COINS = "LeaderboardCoins" -- Name of the part for coins leaderboard
local LEADERBOARD_PART_STUDS = "LeaderboardStuds" -- Name of the part for studs leaderboard

-- Variables
local lastUpdateTime = 0
local activeGUIs = {} -- Track active GUIs to prevent conflicts

-- Function to get all player data sorted by specified stat
local function getLeaderboardData(statType)
	local playerData = {}

	print("🔍 Getting leaderboard data for " .. statType .. "...")
	print("👥 Players in game: " .. #Players:GetPlayers())

	for _, player in pairs(Players:GetPlayers()) do
		print("📊 Checking player: " .. player.Name)

		if player.leaderstats then
			print("✅ " .. player.Name .. " has leaderstats")

			if player.leaderstats[statType] then
				local value = player.leaderstats[statType].Value
				print("💰 " .. player.Name .. " " .. statType .. ": " .. value)

				table.insert(playerData, {
					name = player.Name,
					value = value
				})
			else
				print("❌ " .. player.Name .. " missing " .. statType .. " stat")
			end
		else
			print("❌ " .. player.Name .. " has no leaderstats")
		end
	end

	print("📈 Found " .. #playerData .. " players with " .. statType .. " data")

	-- Sort players by value (highest first)
	table.sort(playerData, function(a, b)
		return a.value > b.value
	end)

	-- Return only top players
	local topPlayers = {}
	for i = 1, math.min(LEADERBOARD_SIZE, #playerData) do
		table.insert(topPlayers, playerData[i])
	end

	return topPlayers
end

-- Function to safely destroy GUI with proper cleanup
local function safeDestroyGUI(part, guiName)
	local existingGUI = part:FindFirstChild(guiName)
	if existingGUI then
		print("🗑️ Safely removing existing GUI: " .. guiName)

		-- Remove from active GUIs tracking
		for i, gui in ipairs(activeGUIs) do
			if gui == existingGUI then
				table.remove(activeGUIs, i)
				break
			end
		end

		existingGUI:Destroy()
		wait(0.2) -- Longer delay to ensure complete cleanup
		return true
	end
	return false
end

-- Function to create leaderboard GUI with error handling
local function createLeaderboardGUI(part, statType, title)
	print("🔨 Creating leaderboard GUI for " .. title)

	-- Ensure part is valid
	if not part or not part.Parent then
		warn("❌ Invalid part provided for GUI creation")
		return nil
	end

	-- Safe cleanup of existing GUI
	safeDestroyGUI(part, "LeaderboardGUI")

	local success, surfaceGui = pcall(function()
		-- Create new GUI
		local gui = Instance.new("SurfaceGui")
		gui.Name = "LeaderboardGUI"
		gui.Face = Enum.NormalId.Front
		gui.Parent = part

		-- Create main frame
		local mainFrame = Instance.new("Frame")
		mainFrame.Name = "MainFrame"
		mainFrame.Size = UDim2.new(1, 0, 1, 0)
		mainFrame.Position = UDim2.new(0, 0, 0, 0)
		mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		mainFrame.BorderSizePixel = 0
		mainFrame.Parent = gui

		-- Add corner rounding
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 15)
		corner.Parent = mainFrame

		-- Create title
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "Title"
		titleLabel.Size = UDim2.new(1, 0, 0.12, 0)
		titleLabel.Position = UDim2.new(0, 0, 0, 0)
		titleLabel.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
		titleLabel.BorderSizePixel = 0
		titleLabel.Text = title
		titleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		titleLabel.TextScaled = true
		titleLabel.Font = Enum.Font.SourceSansBold
		titleLabel.Parent = mainFrame

		-- Add corner rounding to title
		local titleCorner = Instance.new("UICorner")
		titleCorner.CornerRadius = UDim.new(0, 15)
		titleCorner.Parent = titleLabel

		-- Create scrolling frame for leaderboard entries
		local scrollFrame = Instance.new("ScrollingFrame")
		scrollFrame.Name = "ScrollFrame"
		scrollFrame.Size = UDim2.new(1, 0, 0.88, 0)
		scrollFrame.Position = UDim2.new(0, 0, 0.12, 0)
		scrollFrame.BackgroundTransparency = 1
		scrollFrame.ScrollBarThickness = 8
		scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
		scrollFrame.BorderSizePixel = 0
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
		scrollFrame.Parent = mainFrame

		-- Create UI list layout for entries
		local listLayout = Instance.new("UIListLayout")
		listLayout.Name = "ListLayout"
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 2)
		listLayout.Parent = scrollFrame

		-- Create padding for scroll frame
		local padding = Instance.new("UIPadding")
		padding.Name = "Padding"
		padding.PaddingTop = UDim.new(0, 10)
		padding.PaddingBottom = UDim.new(0, 10)
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.Parent = scrollFrame

		return gui
	end)

	if success and surfaceGui then
		-- Add to active GUIs tracking
		table.insert(activeGUIs, surfaceGui)
		print("✅ Successfully created leaderboard GUI for " .. title)
		return surfaceGui
	else
		warn("❌ Failed to create leaderboard GUI: " .. tostring(surfaceGui))
		return nil
	end
end

-- Function to update leaderboard entries with enhanced error checking
local function updateLeaderboardEntries(gui, leaderboardData, statType)
	print("🔄 Updating leaderboard entries with " .. #leaderboardData .. " players")

	-- Validate GUI
	if not gui or not gui.Parent then
		warn("❌ Invalid GUI provided for updating entries")
		return false
	end

	-- Find main frame first
	local mainFrame = gui:FindFirstChild("MainFrame")
	if not mainFrame then
		warn("❌ MainFrame not found in GUI!")
		return false
	end

	-- Find scroll frame
	local scrollFrame = mainFrame:FindFirstChild("ScrollFrame")
	if not scrollFrame then 
		warn("❌ ScrollFrame not found in MainFrame!")
		print("🔍 Available children in MainFrame:")
		for _, child in pairs(mainFrame:GetChildren()) do
			print("   - " .. child.Name .. " (" .. child.ClassName .. ")")
		end
		return false
	end

	print("✅ Found ScrollFrame, proceeding with update")

	-- Safe cleanup of existing entries
	local success, errorMsg = pcall(function()
		-- Only remove entry frames, keep layout and padding
		for _, child in pairs(scrollFrame:GetChildren()) do
			if child:IsA("Frame") and child.Name:match("Entry") then
				child:Destroy()
			end
		end
	end)

	if not success then
		warn("❌ Error clearing old entries: " .. tostring(errorMsg))
		return false
	end

	print("🧹 Cleared old entries, creating " .. #leaderboardData .. " new entries")

	-- Create new entries with error handling
	for i, playerData in ipairs(leaderboardData) do
		print("👤 Creating entry " .. i .. " for " .. playerData.name .. " with " .. playerData.value .. " " .. statType)

		local entrySuccess, entryError = pcall(function()
			local entry = Instance.new("Frame")
			entry.Name = "Entry" .. i
			entry.Size = UDim2.new(1, -20, 0, 40)
			entry.BackgroundColor3 = i <= 3 and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(40, 40, 40)
			entry.BorderSizePixel = 0
			entry.LayoutOrder = i
			entry.Parent = scrollFrame

			-- Add corner rounding to entry
			local entryCorner = Instance.new("UICorner")
			entryCorner.CornerRadius = UDim.new(0, 8)
			entryCorner.Parent = entry

			-- Rank label
			local rankLabel = Instance.new("TextLabel")
			rankLabel.Name = "Rank"
			rankLabel.Size = UDim2.new(0.15, 0, 1, 0)
			rankLabel.Position = UDim2.new(0, 0, 0, 0)
			rankLabel.BackgroundTransparency = 1
			rankLabel.Text = "#" .. i
			rankLabel.TextColor3 = i <= 3 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
			rankLabel.TextScaled = true
			rankLabel.Font = Enum.Font.SourceSansBold
			rankLabel.Parent = entry

			-- Player name label
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "PlayerName"
			nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
			nameLabel.Position = UDim2.new(0.15, 0, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = playerData.name
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextScaled = true
			nameLabel.Font = Enum.Font.SourceSans
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = entry

			-- Value label
			local valueLabel = Instance.new("TextLabel")
			valueLabel.Name = "Value"
			valueLabel.Size = UDim2.new(0.35, 0, 1, 0)
			valueLabel.Position = UDim2.new(0.65, 0, 0, 0)
			valueLabel.BackgroundTransparency = 1
			valueLabel.Text = NumberFormatter.formatNumber(playerData.value)
			valueLabel.TextColor3 = statType == "Coins" and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(0, 255, 127)
			valueLabel.TextScaled = true
			valueLabel.Font = Enum.Font.SourceSansBold
			valueLabel.TextXAlignment = Enum.TextXAlignment.Right
			valueLabel.Parent = entry

			-- Add crown icon for top 3
			if i <= 3 then
				local crownLabel = Instance.new("TextLabel")
				crownLabel.Name = "Crown"
				crownLabel.Size = UDim2.new(0, 30, 0, 30)
				crownLabel.Position = UDim2.new(0, -35, 0.5, -15)
				crownLabel.BackgroundTransparency = 1
				crownLabel.Text = i == 1 and "👑" or (i == 2 and "🥈" or "🥉")
				crownLabel.TextScaled = true
				crownLabel.Parent = entry
			end
		end)

		if not entrySuccess then
			warn("❌ Failed to create entry " .. i .. ": " .. tostring(entryError))
		else
			print("✅ Created entry for " .. playerData.name)
		end
	end

	-- Update scroll frame canvas size
	local totalHeight = #leaderboardData * 42 + 20
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)

	print("📏 Updated canvas size to " .. totalHeight .. " pixels")
	print("✅ Finished updating leaderboard entries")
	return true
end

-- Function to update all leaderboards with better error handling
local function updateLeaderboards()
	print("🔄 Starting leaderboard update...")
	print("⏰ Current time: " .. os.date("%X"))

	-- Check if parts exist first
	local coinsPart = workspace:FindFirstChild(LEADERBOARD_PART_COINS)
	local studsPart = workspace:FindFirstChild(LEADERBOARD_PART_STUDS)

	print("🔍 Checking for leaderboard parts...")
	print("🪙 Coins part '" .. LEADERBOARD_PART_COINS .. "': " .. (coinsPart and "FOUND" or "NOT FOUND"))
	print("💎 Studs part '" .. LEADERBOARD_PART_STUDS .. "': " .. (studsPart and "FOUND" or "NOT FOUND"))

	-- Update Coins leaderboard
	if coinsPart and coinsPart.Parent then
		local coinsData = getLeaderboardData("Coins")
		local coinsGUI = coinsPart:FindFirstChild("LeaderboardGUI")

		if not coinsGUI then
			print("🔨 Creating new Coins leaderboard GUI...")
			coinsGUI = createLeaderboardGUI(coinsPart, "Coins", "🪙 TOP COINS LEADERBOARD 🪙")
		end

		if coinsGUI and coinsGUI.Parent then
			local updateSuccess = updateLeaderboardEntries(coinsGUI, coinsData, "Coins")
			if updateSuccess then
				print("✅ Updated Coins leaderboard with " .. #coinsData .. " players")
			else
				warn("❌ Failed to update Coins leaderboard entries")
			end
		else
			warn("❌ Failed to create or access Coins GUI")
		end
	else
		warn("⚠️ CRITICAL: Coins leaderboard part '" .. LEADERBOARD_PART_COINS .. "' not found or invalid in workspace!")
		print("💡 Create a part in workspace named exactly: " .. LEADERBOARD_PART_COINS)
	end

	-- Update Studs leaderboard
	if studsPart and studsPart.Parent then
		local studsData = getLeaderboardData("Studs")
		local studsGUI = studsPart:FindFirstChild("LeaderboardGUI")

		if not studsGUI then
			print("🔨 Creating new Studs leaderboard GUI...")
			studsGUI = createLeaderboardGUI(studsPart, "Studs", "💎 TOP STUDS LEADERBOARD 💎")
		end

		if studsGUI and studsGUI.Parent then
			local updateSuccess = updateLeaderboardEntries(studsGUI, studsData, "Studs")
			if updateSuccess then
				print("✅ Updated Studs leaderboard with " .. #studsData .. " players")
			else
				warn("❌ Failed to update Studs leaderboard entries")
			end
		else
			warn("❌ Failed to create or access Studs GUI")
		end
	else
		warn("⚠️ CRITICAL: Studs leaderboard part '" .. LEADERBOARD_PART_STUDS .. "' not found or invalid in workspace!")
		print("💡 Create a part in workspace named exactly: " .. LEADERBOARD_PART_STUDS)
	end

	print("✅ Leaderboard update completed!")
	print("=" .. string.rep("=", 50))
end

-- Function to setup leaderboards when players join/leave
local function onPlayerAdded(player)
	-- Wait for leaderstats to be created
	player:WaitForChild("leaderstats", 30)

	-- Small delay then update leaderboards
	wait(2)
	updateLeaderboards()
end

local function onPlayerRemoving(player)
	-- Update leaderboards when a player leaves
	wait(1) -- Small delay to ensure player data is processed
	updateLeaderboards()
end

-- Initialize the leaderboard system
local function initializeLeaderboards()
	print("🚀 Initializing Leaderboard System...")

	-- Connect player events
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Initial update
	wait(3) -- Wait for other systems to initialize
	updateLeaderboards()

	print("✅ Leaderboard System initialized!")
	print("📊 Leaderboards will update every " .. (UPDATE_INTERVAL) .. " seconds")
	print("🎯 Looking for parts: '" .. LEADERBOARD_PART_COINS .. "' and '" .. LEADERBOARD_PART_STUDS .. "'")
end

-- Enhanced main update loop with error handling
RunService.Heartbeat:Connect(function()
	local currentTime = tick()

	if currentTime - lastUpdateTime >= UPDATE_INTERVAL then
		local success, errorMsg = pcall(updateLeaderboards)
		if not success then
			warn("❌ Error in leaderboard update: " .. tostring(errorMsg))
		end
		lastUpdateTime = currentTime
	end
end)

-- Cleanup function for when script is reloaded
local function cleanup()
	for _, gui in ipairs(activeGUIs) do
		if gui and gui.Parent then
			gui:Destroy()
		end
	end
	activeGUIs = {}
end

-- Start the system
initializeLeaderboards()

-- Manual update function for testing
_G.UpdateLeaderboards = updateLeaderboards
_G.CleanupLeaderboards = cleanup

print("📋 Leaderboard System loaded successfully!")
print("💡 Use _G.UpdateLeaderboards() to manually update leaderboards for testing")
print("🧹 Use _G.CleanupLeaderboards() to clean up GUIs if needed")
