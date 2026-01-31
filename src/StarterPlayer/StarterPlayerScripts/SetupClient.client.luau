-- Wait for the local player and PlayerGui to load
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local player = Players.LocalPlayer

-- Wait for the ScreenGui to load
local playerGui = player:WaitForChild("PlayerGui")
local startMenuGui = playerGui:WaitForChild(Constants.UI_ELEMENTS.GUI.START_MENU)
local storeGui = playerGui:WaitForChild(Constants.UI_ELEMENTS.GUI.STORE)
startMenuGui.Enabled = true
storeGui.Enabled = false

local startMenu = startMenuGui:WaitForChild(Constants.UI_ELEMENTS.FRAMES.START_MENU)
local startButton = startMenu:WaitForChild(Constants.UI_ELEMENTS.BUTTONS.START)

-- Function to handle button click
local function onStartButtonClicked()
	-- Wait for the character to load
	local character = player.Character or player.CharacterAdded:Wait()

	startMenuGui.Enabled = false

	-- Find the spawn location
	local track1Spawn =
		workspace:WaitForChild(Constants.WORLD_OBJECTS.TRACK_1):WaitForChild(Constants.WORLD_OBJECTS.TRACK_1_SPAWN)

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
