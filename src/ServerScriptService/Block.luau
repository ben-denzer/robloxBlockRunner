-- Block collection and respawning system

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

-- Track recently collected blocks to prevent double collection
local recentlyCollected = {}

-- Store block templates for respawning
local blockTemplates = {}
local nextBlockId = 1

-- Store blocks that failed to respawn due to players being in the way
local respawnStorage = {}

-- Function to setup player block count
local function setupPlayerBlockCount(player)
	player:SetAttribute("BlockCount", 0)
end

-- Function to create a block from template
local function createBlockFromTemplate(template)
	local newBlock = Instance.new("Part")
	newBlock.Size = template.Size
	newBlock.Position = template.Position
	newBlock.Anchored = template.Anchored
	newBlock.CanCollide = template.CanCollide
	newBlock.Material = template.Material
	newBlock.Color = template.Color
	newBlock.Name = template.Name
	newBlock.Parent = template.Parent

	-- Copy attributes
	for attributeName, attributeValue in pairs(template.Attributes) do
		newBlock:SetAttribute(attributeName, attributeValue)
	end

	-- Add the "block" tag
	CollectionService:AddTag(newBlock, "block")

	return newBlock
end

-- Function to check if a player is near the respawn position
local function isPlayerNearPosition(position, radius)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local distance = (humanoidRootPart.Position - position).Magnitude
				if distance <= radius then
					return true
				end
			end
		end
	end
	return false
end

-- Function to periodically try respawning stored blocks
local function tryRespawnStoredBlocks()
	for storageId, template in pairs(respawnStorage) do
		local playerNearby = isPlayerNearPosition(template.Position, 5)

		if not playerNearby then
			-- Safe to respawn now
			createBlockFromTemplate(template)
			respawnStorage[storageId] = nil
		end
	end
end

-- Function to handle block collection
local function onBlockTouched(block, hit)
	-- Use block position as unique identifier for debounce (since block will be destroyed)
	local blockKey = tostring(block.Position)

	-- Check if this block was recently collected to prevent double collection
	if recentlyCollected[blockKey] then
		return
	end

	-- Check if the hit part is part of a player's character
	local character = hit:FindFirstAncestorOfClass("Model")
	if character then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			-- Mark this block as recently collected
			recentlyCollected[blockKey] = true

			-- Generate unique ID for template storage (separate from debounce key)
			local templateId = nextBlockId
			nextBlockId = nextBlockId + 1

			-- Get the count from the block's attribute, default to 1
			local count = block:GetAttribute("Count") or 1

			-- Increment the player's block count attribute
			local currentCount = player:GetAttribute("BlockCount") or 0
			player:SetAttribute("BlockCount", currentCount + count)

			-- Store template for respawning
			local template = {
				Size = block.Size,
				Position = block.Position,
				Anchored = block.Anchored,
				CanCollide = block.CanCollide,
				Material = block.Material,
				Color = block.Color,
				Name = block.Name,
				Parent = block.Parent,
				Attributes = {},
			}

			-- Store all attributes
			for _, attributeName in ipairs(block:GetAttributes()) do
				template.Attributes[attributeName] = block:GetAttribute(attributeName)
			end

			blockTemplates[templateId] = template

			-- Destroy the block
			block:Destroy()

			-- Respawn the block with retry logic if players are in the way
			local function tryRespawn(attemptNumber)
				if not blockTemplates[templateId] then
					return
				end

				local playerNearby = isPlayerNearPosition(template.Position, 5) -- 5 stud radius

				if playerNearby and attemptNumber < 5 then -- Try up to 5 times (75 seconds total)
					-- Wait 15 more seconds and try again
					task.delay(15, function()
						tryRespawn(attemptNumber + 1)
					end)
				else
					-- Either no player nearby or max attempts reached
					if playerNearby then
						-- Max attempts reached but still blocked - store for later retry
						respawnStorage[templateId] = template
					else
						-- Safe to respawn now
						createBlockFromTemplate(template)
					end
					blockTemplates[templateId] = nil
				end
			end

			-- Start the respawn process
			task.delay(15, function()
				tryRespawn(1)
			end)

			-- Clear the debounce after a short delay
			task.delay(0.1, function()
				recentlyCollected[blockKey] = nil
			end)
		end
	end
end

-- Initialize block system
local function init()
	-- Setup all existing blocks
	for _, block in ipairs(CollectionService:GetTagged("block")) do
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

	-- Start periodic check for stored blocks every 60 seconds
	task.spawn(function()
		while true do
			task.wait(60) -- Wait 60 seconds
			tryRespawnStoredBlocks()
		end
	end)
end

return {
	init = init,
	setupPlayerBlockCount = setupPlayerBlockCount,
}