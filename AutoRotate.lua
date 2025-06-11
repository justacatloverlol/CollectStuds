-- AutoRotate.lua
-- Place this script inside any part you want to rotate
-- This should be a SERVER SCRIPT (not LocalScript)

local RunService = game:GetService("RunService")

-- Configuration
local ROTATION_SPEED = 2 -- Rotations per second (adjust as needed)
local ROTATION_AXIS = Vector3.new(0, 1, 0) -- Y-axis rotation (spins horizontally)
-- Other axis options:
-- Vector3.new(1, 0, 0) = X-axis (front to back flip)
-- Vector3.new(0, 0, 1) = Z-axis (side to side flip)
-- Vector3.new(1, 1, 1) = All axes (tumbling)

-- Get the part this script is inside
local part = script.Parent

-- Make sure the part is anchored so it doesn't fall while rotating
part.Anchored = true

-- Calculate rotation per frame
local rotationPerSecond = ROTATION_SPEED * math.pi * 2 -- Convert to radians
local lastTime = tick()

-- Connect to heartbeat for smooth rotation
local connection = RunService.Heartbeat:Connect(function()
	local currentTime = tick()
	local deltaTime = currentTime - lastTime
	lastTime = currentTime

	-- Calculate rotation amount for this frame
	local rotationAmount = rotationPerSecond * deltaTime

	-- Create rotation CFrame
	local rotationCFrame = CFrame.Angles(
		ROTATION_AXIS.X * rotationAmount,
		ROTATION_AXIS.Y * rotationAmount,
		ROTATION_AXIS.Z * rotationAmount
	)

	-- Apply rotation to the part
	part.CFrame = part.CFrame * rotationCFrame
end)

-- Optional: Clean up when part is removed
part.AncestryChanged:Connect(function()
	if not part.Parent then
		connection:Disconnect()
	end
end)
