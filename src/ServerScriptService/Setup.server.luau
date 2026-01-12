-- Setup server script for baseplate death mechanic

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Initialize block system
local BlockSystem = require(game:GetService("ServerScriptService").Block)
BlockSystem.init()

-- Wait for the baseplate to exist (in case it's loaded after this script)
local baseplate = Workspace:WaitForChild("Baseplate")

-- Make baseplate non-collidable from the start
baseplate.CanCollide = false

-- Function to handle player touching baseplate
local function onBaseplateTouched(hit)
	-- Check if the hit part is part of a player's character
	local character = hit:FindFirstAncestorOfClass("Model")
	if character then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			-- Kill the player
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end
	end
end

-- Connect the touched event
baseplate.Touched:Connect(onBaseplateTouched)
