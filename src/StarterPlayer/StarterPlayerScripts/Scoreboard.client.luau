-- Scoreboard functionality for displaying block count and cash
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Function to get the block count label (handles potential GUI resets)
local function getBlockCountLabel()
	local success, result = pcall(function()
		local scoreboardGui = playerGui:FindFirstChild("ScoreboardGui")
		if scoreboardGui then
			local scoreboard = scoreboardGui:FindFirstChild("Scoreboard")
			if scoreboard then
				return scoreboard:FindFirstChild("BlockCount")
			end
		end
		return nil
	end)
	return success and result or nil
end

-- Function to get the cash label (handles potential GUI resets)
local function getCashLabel()
	local success, result = pcall(function()
		local scoreboardGui = playerGui:FindFirstChild("ScoreboardGui")
		if scoreboardGui then
			local scoreboard = scoreboardGui:FindFirstChild("Scoreboard")
			if scoreboard then
				return scoreboard:FindFirstChild("CashCount")
			end
		end
		return nil
	end)
	return success and result or nil
end

-- Wait for the Scoreboard GUI to load initially (for initial setup)
playerGui:WaitForChild("ScoreboardGui"):WaitForChild("Scoreboard"):WaitForChild("BlockCount")

-- Function to format cash with commas (e.g., 1000 -> 1,000)
local function formatCash(amount)
	local str = tostring(math.floor(amount))
	local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	-- Remove leading comma if present
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return formatted
end

-- Function to update the block count display
local function updateBlockCountDisplay()
	local label = getBlockCountLabel()
	if label then
		local blockCount = player:GetAttribute("BlockCount") or 0
		label.Text = tostring(blockCount) .. " / " .. tostring(player:GetAttribute("WagonSize"))
	end
end

-- Function to update the cash display
local function updateCashDisplay()
	local label = getCashLabel()
	if label then
		local cash = player:GetAttribute("Cash") or 0
		label.Text = "$" .. formatCash(cash)
	end
end
-- Initialize with current block count, wagon size, and cash
updateBlockCountDisplay()
updateCashDisplay()

-- Listen for BlockCount attribute changes
player:GetAttributeChangedSignal("BlockCount"):Connect(updateBlockCountDisplay)

-- Listen for WagonSize attribute changes
player:GetAttributeChangedSignal("WagonSize"):Connect(updateBlockCountDisplay)

-- Listen for Cash attribute changes
player:GetAttributeChangedSignal("Cash"):Connect(updateCashDisplay)

-- Also update on character respawn (in case GUI gets reset)
player.CharacterAdded:Connect(function()
	task.wait(0.1) -- Small delay to ensure GUI is ready
	updateBlockCountDisplay()
	updateCashDisplay()
end)
