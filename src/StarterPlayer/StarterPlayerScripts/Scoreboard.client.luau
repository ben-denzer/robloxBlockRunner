-- Scoreboard functionality for displaying block count
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

-- Wait for the Scoreboard GUI to load initially (for initial setup)
playerGui:WaitForChild("ScoreboardGui"):WaitForChild("Scoreboard"):WaitForChild("BlockCount")

-- Function to update the block count display
local function updateBlockCountDisplay()
	local label = getBlockCountLabel()
	if label then
		local blockCount = player:GetAttribute("BlockCount") or 0
		label.Text = tostring(blockCount)
	end
end

-- Initialize with current block count
updateBlockCountDisplay()

-- Listen for BlockCount attribute changes
player:GetAttributeChangedSignal("BlockCount"):Connect(updateBlockCountDisplay)

-- Also update on character respawn (in case GUI gets reset)
player.CharacterAdded:Connect(function()
	task.wait(0.1) -- Small delay to ensure GUI is ready
	updateBlockCountDisplay()
end)
