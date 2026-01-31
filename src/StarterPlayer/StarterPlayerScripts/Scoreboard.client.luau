-- Scoreboard functionality for displaying block count and cash
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Utils = require(ReplicatedStorage:WaitForChild("Utils"))
-- Function to get the block count label (handles potential GUI resets)
local function getBlockCountLabel()
	local success, result = pcall(function()
		local scoreboardGui = playerGui:FindFirstChild(Constants.UI_ELEMENTS.GUI.SCOREBOARD)
		if scoreboardGui then
			local scoreboard = scoreboardGui:FindFirstChild(Constants.UI_ELEMENTS.FRAMES.SCOREBOARD)
			if scoreboard then
				return scoreboard:FindFirstChild(Constants.UI_ELEMENTS.ELEMENTS.BLOCK_COUNT)
			end
		end
		return nil
	end)
	return success and result or nil
end

-- Function to get the cash label (handles potential GUI resets)
local function getCashLabel()
	local success, result = pcall(function()
		local scoreboardGui = playerGui:FindFirstChild(Constants.UI_ELEMENTS.GUI.SCOREBOARD)
		if scoreboardGui then
			local scoreboard = scoreboardGui:FindFirstChild(Constants.UI_ELEMENTS.FRAMES.SCOREBOARD)
			if scoreboard then
				return scoreboard:FindFirstChild(Constants.UI_ELEMENTS.ELEMENTS.CASH_COUNT)
			end
		end
		return nil
	end)
	return success and result or nil
end

-- Wait for the Scoreboard GUI to load initially (for initial setup)
playerGui
	:WaitForChild(Constants.UI_ELEMENTS.GUI.SCOREBOARD)
	:WaitForChild(Constants.UI_ELEMENTS.FRAMES.SCOREBOARD)
	:WaitForChild(Constants.UI_ELEMENTS.ELEMENTS.BLOCK_COUNT)

-- Function to update the block count display
local function updateBlockCountDisplay()
	local label = getBlockCountLabel()
	if label then
		local blockCount = player:GetAttribute(Constants.PLAYER_ATTRIBUTES.BLOCK_COUNT) or 0
		label.Text = tostring(blockCount)
			.. " / "
			.. tostring(player:GetAttribute(Constants.PLAYER_ATTRIBUTES.WAGON_SIZE))
	end
end

-- Function to update the cash display
local function updateCashDisplay()
	local label = getCashLabel()
	if label then
		local cash = player:GetAttribute(Constants.PLAYER_ATTRIBUTES.CASH) or 0
		label.Text = "$" .. Utils.formatCash(cash)
	end
end
-- Initialize with current block count, wagon size, and cash
updateBlockCountDisplay()
updateCashDisplay()

-- Listen for BlockCount attribute changes
player:GetAttributeChangedSignal(Constants.PLAYER_ATTRIBUTES.BLOCK_COUNT):Connect(updateBlockCountDisplay)

-- Listen for WagonSize attribute changes
player:GetAttributeChangedSignal(Constants.PLAYER_ATTRIBUTES.WAGON_SIZE):Connect(updateBlockCountDisplay)

-- Listen for Cash attribute changes
player:GetAttributeChangedSignal(Constants.PLAYER_ATTRIBUTES.CASH):Connect(updateCashDisplay)

-- Also update on character respawn (in case GUI gets reset)
player.CharacterAdded:Connect(function()
	task.wait(0.1) -- Small delay to ensure GUI is ready
	updateBlockCountDisplay()
	updateCashDisplay()
end)
