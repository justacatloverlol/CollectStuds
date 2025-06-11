-- NumberFormatter.lua
-- Place this ModuleScript in ReplicatedStorage
-- This module formats large numbers into readable format (1.2B, 456.7M, etc.)

local NumberFormatter = {}

-- Suffix table for large numbers
local suffixes = {
	{1e12, "T"},   -- Trillion
	{1e9,  "B"},   -- Billion
	{1e6,  "M"},   -- Million
	{1e3,  "K"}    -- Thousand
}

-- Function to format numbers
function NumberFormatter.formatNumber(number)
	-- Handle negative numbers
	local isNegative = number < 0
	number = math.abs(number)

	-- Handle small numbers (less than 1000)
	if number < 1000 then
		return isNegative and "-" .. tostring(number) or tostring(number)
	end

	-- Find appropriate suffix
	for _, data in ipairs(suffixes) do
		local threshold = data[1]
		local suffix = data[2]

		if number >= threshold then
			local formatted = number / threshold

			-- Format to 1 decimal place if needed
			if formatted >= 100 then
				-- 100+ shows as whole number (e.g., "123B")
				formatted = math.floor(formatted)
				return isNegative and "-" .. tostring(formatted) .. suffix or tostring(formatted) .. suffix
			elseif formatted >= 10 then
				-- 10-99 shows 1 decimal (e.g., "12.3B")
				formatted = math.floor(formatted * 10) / 10
				return isNegative and "-" .. tostring(formatted) .. suffix or tostring(formatted) .. suffix
			else
				-- 1-9 shows 1 decimal (e.g., "1.2B")
				formatted = math.floor(formatted * 10) / 10
				return isNegative and "-" .. tostring(formatted) .. suffix or tostring(formatted) .. suffix
			end
		end
	end

	-- Fallback (should never reach here)
	return isNegative and "-" .. tostring(number) or tostring(number)
end

-- Function to format currency specifically (adds commas for smaller numbers)
function NumberFormatter.formatCurrency(number)
	-- For numbers less than 1000, add commas
	if math.abs(number) < 1000 then
		return tostring(number)
	end

	-- For larger numbers, use suffix formatting
	return NumberFormatter.formatNumber(number)
end

-- Test function (remove in production)
function NumberFormatter.test()
	local testNumbers = {
		0, 1, 50, 999, 1000, 1500, 10000, 50000, 
		1000000, 1500000, 2500000, 1000000000, 
		1500000000, 1000000000000, -5000000
	}

	print("=== Number Formatter Test ===")
	for _, num in ipairs(testNumbers) do
		print(num .. " -> " .. NumberFormatter.formatNumber(num))
	end
end

return NumberFormatter
