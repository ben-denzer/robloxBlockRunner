-- Setup server script for baseplate death mechanic

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

-- Track recently collected blocks to prevent double collection
local recentlyCollected = {}

-- Wait for the baseplate to exist (in case it's loaded after this script)
local baseplate = Workspace:WaitForChild("Baseplate")

-- Make baseplate non-collidable from the start
baseplate.CanCollide = false

-- Function to setup player block count
local function setupPlayerBlockCount(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local blockCount = Instance.new("NumberValue")
	blockCount.Name = "BlockCount"
	blockCount.Value = 0
	blockCount.Parent = leaderstats
end

-- Function to handle block collection
local function onBlockTouched(block, hit)
	-- Check if this block was recently collected to prevent double collection
	if recentlyCollected[block] then
		return
	end

	-- Check if the hit part is part of a player's character
	local character = hit:FindFirstAncestorOfClass("Model")
	if character then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			-- Mark this block as recently collected
			recentlyCollected[block] = true

			-- Get the count from the block's attribute, default to 1
			local count = block:GetAttribute("Count") or 1

			-- Find the player's block count and increment it
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local blockCount = leaderstats:FindFirstChild("BlockCount")
				if blockCount then
					blockCount.Value = blockCount.Value + count
				end
			end

			-- Destroy the block
			block:Destroy()

			-- Clear the debounce after a short delay
			task.delay(0.1, function()
				recentlyCollected[block] = nil
			end)
		end
	end
end

-- Setup all existing blocks
for _, block in ipairs(CollectionService:GetTagged("block")) do
	print(`Setting up block: {block.Name}`)
	block.Touched:Connect(function(hit)
		onBlockTouched(block, hit)
	end)
end

-- Listen for new blocks being tagged
CollectionService:GetInstanceAddedSignal("block"):Connect(function(block)
	block.Touched:Connect(function(hit)
		onBlockTouched(block, hit)
	end)
end)

-- Setup block count for existing players
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayerBlockCount(player)
end

-- Listen for new players joining
Players.PlayerAdded:Connect(setupPlayerBlockCount)

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
