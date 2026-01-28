-- Wait for the local player and PlayerGui to load
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Wait for the ScreenGui to load
local playerGui = player:WaitForChild("PlayerGui")
local startMenuGui = playerGui:WaitForChild("StartMenuGui")
startMenuGui.Enabled = true

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

local startMenu = startMenuGui:WaitForChild("StartMenu")
local startButton = startMenu:WaitForChild("Start Button")

-- Function to handle button click
local function onStartButtonClicked()
	-- Wait for the character to load
	local character = player.Character or player.CharacterAdded:Wait()

	startMenuGui.Enabled = false

	-- Find the spawn location
	local track1Spawn = workspace:WaitForChild("Track1"):WaitForChild("Track1Spawn")

	-- Move the character to the spawn location (above it so they land on it)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local spawnCFrame = track1Spawn.CFrame

	-- Calculate spawn height based on character size
	local characterHeight = (character:GetExtentsSize().Y / 2) + 2 -- Half height + 2 studs buffer
	local spawnAbove = spawnCFrame.Position + Vector3.new(0, characterHeight, 0)

	humanoidRootPart.CFrame = CFrame.new(spawnAbove) * (spawnCFrame - spawnCFrame.Position)
end

-- Connect the button's click event
startButton.MouseButton1Click:Connect(onStartButtonClicked)

-- Then get the event directly from ReplicatedStorage (same instance as server)
local openStoreEvent = ReplicatedStorage:WaitForChild("OpenStoreEvent")

openStoreEvent.OnClientEvent:Connect(function()
	-- Debug: Check if StoreGui exists
	local storeGui = playerGui:FindFirstChild("StoreGui")
	if not storeGui then
		warn("StoreGui not found in PlayerGui! Contents:", playerGui:GetChildren())
		return
	end

	storeGui.Enabled = true

	-- Ensure BuyOrSell menu is visible (in case other menus were previously shown)
	local buyOrSellMenu = storeGui:FindFirstChild("BuyOrSell")
	if not buyOrSellMenu then
		warn("BuyOrSell menu not found in StoreGui!")
		return
	end

	buyOrSellMenu.Visible = true
end)
