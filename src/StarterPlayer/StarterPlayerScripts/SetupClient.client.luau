-- Wait for the local player and PlayerGui to load
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- Wait for the ScreenGui to load
local playerGui = player:WaitForChild("PlayerGui")
local startMenuGui = playerGui:WaitForChild("StartMenuGui")
local storeGui = playerGui:WaitForChild("StoreGui")
startMenuGui.Enabled = true
storeGui.Enabled = false

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
