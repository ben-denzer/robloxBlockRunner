-- Block collection and respawning system

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local DataManager = require(game:GetService("ServerScriptService").DataManager)
local Constants = require(game:GetService("ReplicatedStorage").Constants)

-- Track recently collected blocks to prevent double collection
local recentlyCollected = {}

-- Store block templates for respawning
local blockTemplates = {}
local nextBlockId = 1

-- Store blocks that failed to respawn due to players being in the way
local respawnStorage = {}

-- Track recently placed blocks to maintain spacing
local recentlyPlacedBlocks = {}
-- Track per-player placement cooldowns
local playerPlacementCooldowns = {}
local PLACEMENT_COOLDOWN = 0 -- Seconds between block placements per player

-- Track fake floor touch debounce per player
local fakeFloorTouchDebounce = {}

-- Function to check if a position is safe for block placement (no overlaps)
local function isPositionSafeForBlock(position, blockSize)
	-- Check for nearby stepping stones (prevent stacking)
	local nearbySteppingStones = CollectionService:GetTagged("stepping-stone")
	for _, existingStone in ipairs(nearbySteppingStones) do
		local distance = (position - existingStone.Position).Magnitude
		-- Ensure blocks don't overlap by keeping them at least their size apart
		local minDistance = math.max(blockSize.X, blockSize.Y, blockSize.Z)
		if distance < minDistance then
			return false -- Too close to existing stepping stone
		end
	end

	-- Don't place on or near track parts - use precise AABB overlap detection
	local nearbyTracks = CollectionService:GetTagged("track")
	for _, trackPart in ipairs(nearbyTracks) do
		-- Check if the block would overlap with the track using AABB (Axis-Aligned Bounding Box)
		local trackMin = trackPart.Position - (trackPart.Size / 2)
		local trackMax = trackPart.Position + (trackPart.Size / 2)
		local blockMin = position - (blockSize / 2)
		local blockMax = position + (blockSize / 2)

		-- AABB overlap test - check if boxes intersect in all 3 dimensions
		if
			blockMax.X > trackMin.X
			and blockMin.X < trackMax.X
			and blockMax.Y > trackMin.Y
			and blockMin.Y < trackMax.Y
			and blockMax.Z > trackMin.Z
			and blockMin.Z < trackMax.Z
		then
			return false -- Block would overlap with track
		end
	end

	return true
end

-- Function to find the closest safe position for block placement
local function findClosestSafePosition(preferredPosition, blockSize)
	-- First, try the preferred position
	if isPositionSafeForBlock(preferredPosition, blockSize) then
		return preferredPosition
	end

	-- Search in order of increasing distance for the closest safe position
	local maxSearchDistance = 4 -- studs
	local stepSize = 1

	for distance = stepSize, maxSearchDistance, stepSize do
		-- Check in a pattern: right, left, forward, back, then diagonals
		local offsets = {
			{ distance, 0 }, -- right
			{ -distance, 0 }, -- left
			{ 0, distance }, -- forward
			{ 0, -distance }, -- back
			{ distance, distance }, -- diagonal
			{ distance, -distance }, -- diagonal
			{ -distance, distance }, -- diagonal
			{ -distance, -distance }, -- diagonal
		}

		-- Also check intermediate positions at this distance
		for i = 1, 4 do
			local intermediateDistance = distance * (i / 4)
			table.insert(offsets, { intermediateDistance, 0 })
			table.insert(offsets, { -intermediateDistance, 0 })
			table.insert(offsets, { 0, intermediateDistance })
			table.insert(offsets, { 0, -intermediateDistance })
		end

		for _, offset in ipairs(offsets) do
			local testPosition =
				Vector3.new(preferredPosition.X + offset[1], preferredPosition.Y, preferredPosition.Z + offset[2])

			if isPositionSafeForBlock(testPosition, blockSize) then
				return testPosition
			end
		end
	end

	return nil -- No safe position found
end

-- Function to check if a player can place a block at this position (spacing and cooldown check)
local function canPlaceBlockAtPosition(player, position, blockSize, isDirectPlacement)
	local currentTime = tick()
	local userId = player.UserId

	-- Check player's personal cooldown
	local lastPlacementTime = playerPlacementCooldowns[userId]
	if lastPlacementTime and (currentTime - lastPlacementTime) < PLACEMENT_COOLDOWN then
		return false -- Player is still on cooldown
	end

	-- For direct placements (under falling players), skip spacing checks
	if isDirectPlacement then
		return true
	end

	-- Calculate minimum spacing: block width + 25% gap to prevent overlaps
	local blockWidth = math.max(blockSize.X, blockSize.Z)
	local minSpacing = blockWidth + (blockWidth * 0.25)

	-- Check spacing from recently placed blocks
	for _, placedData in pairs(recentlyPlacedBlocks) do
		local distance = (position - placedData.position).Magnitude
		if distance < minSpacing then
			return false
		end

		-- Clean up old entries (older than 10 seconds)
		if currentTime - placedData.timestamp > 10 then
			recentlyPlacedBlocks[placedData.id] = nil
		end
	end

	return true
end

-- Function to place a block underneath a player
local function placeBlockUnderPlayer(player, fakeFloorPart)
	local character = player.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local blockTemplate = workspace:FindFirstChild("BlockTemplate")
	if not blockTemplate then
		warn("BlockTemplate not found in Workspace")
		return
	end

	-- Check if player has blocks to place
	local currentBlockCount = player:GetAttribute("BlockCount") or 0
	if currentBlockCount <= 0 then
		return -- Player has no blocks to place
	end

	-- Calculate position for the block
	local playerPos = humanoidRootPart.Position
	local blockSize = blockTemplate.Size

	-- Keep the block at the fake-floor height
	local blockY = fakeFloorPart.Position.Y + 0.5

	-- Get player's movement direction to place blocks in front when moving
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local preferredPos = Vector3.new(playerPos.X, blockY, playerPos.Z)

	if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
		-- Player is moving, place block in front of their movement direction
		local moveDirection = humanoid.MoveDirection.Unit
		local forwardOffset = 5 -- studs ahead in movement direction
		preferredPos = Vector3.new(
			playerPos.X + moveDirection.X * forwardOffset,
			blockY,
			playerPos.Z + moveDirection.Z * forwardOffset
		)
	end

	-- Find the closest safe position for the block (prefer calculated position)
	local isDirectPlacement = true
	local blockPosition = findClosestSafePosition(preferredPos, blockSize)

	if not blockPosition then
		return -- No safe position found (should be very rare)
	end

	-- For direct placements on fake-floor, skip spacing checks but keep overlap protection
	-- This ensures players get blocks when on fake-floor but prevents stacking on existing blocks
	if not isDirectPlacement then
		if not canPlaceBlockAtPosition(player, blockPosition, blockSize, isDirectPlacement) then
			return
		end
	end

	-- Decrement the player's block count
	local currentCount = player:GetAttribute("BlockCount") or 0
	local newCount = math.max(0, currentCount - 1) -- Don't go below 0
	DataManager.updatePlayerData(player, "BlockCount", newCount)

	-- Clone and place the block
	local newBlock = blockTemplate:Clone()
	newBlock.Position = blockPosition
	newBlock.Anchored = true -- Make it anchored so it stays in place
	newBlock.Parent = workspace

	-- Tag as stepping stone (not "block" to avoid interfering with collectible blocks)
	CollectionService:AddTag(newBlock, "stepping-stone")

	-- Schedule block destruction after 5 seconds
	task.delay(3, function()
		if newBlock and newBlock.Parent then
			newBlock:Destroy()
		end
	end)

	-- Set player's cooldown
	playerPlacementCooldowns[player.UserId] = tick()

	-- Add to recently placed blocks tracking
	local placementId = tostring(blockPosition)
	recentlyPlacedBlocks[placementId] = {
		position = blockPosition,
		timestamp = tick(),
		id = placementId,
	}

	-- Clean up old entries periodically
	for id, data in pairs(recentlyPlacedBlocks) do
		if tick() - data.timestamp > 30 then -- Clean up entries older than 30 seconds
			recentlyPlacedBlocks[id] = nil
		end
	end
end

-- Function to handle fake-floor touching
local function onFakeFloorTouched(fakeFloorPart, hit)
	-- Check if the hit part is part of a player's character
	local character = hit:FindFirstAncestorOfClass("Model")
	if character then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			-- Debounce: only allow every 200ms per player
			local currentTime = tick()
			local lastTouchTime = fakeFloorTouchDebounce[player.UserId]
			if not lastTouchTime or (currentTime - lastTouchTime) >= 0.2 then
				fakeFloorTouchDebounce[player.UserId] = currentTime
				placeBlockUnderPlayer(player, fakeFloorPart)
			end
		end
	end
end

-- Function to update a player's collision group based on their BlockCount
local function updatePlayerCollisionGroup(player)
	local character = player.Character
	if not character then
		return
	end

	local blockCount = player:GetAttribute("BlockCount") or 0
	local collisionGroup = blockCount > 0 and "PlayersWithBlocks" or "PlayersWithoutBlocks"

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = collisionGroup
			part.CanTouch = true -- Ensure touch events can fire
		end
	end
end

-- Function to set all parts in a character to the appropriate collision group
local function setCharacterCollisionGroup(character, player)
	if not player or not character then
		return
	end
	updatePlayerCollisionGroup(player)
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

	-- Ensure Count attribute exists (default to 1 if missing)
	if not newBlock:GetAttribute("Count") then
		newBlock:SetAttribute("Count", 1)
	end

	-- Add the "block" tag
	CollectionService:AddTag(newBlock, "block")

	-- Set properties in correct order for touch detection
	-- Ensure CanCollide is true first (needed for touch detection)
	if not newBlock.CanCollide then
		newBlock.CanCollide = true
	end
	-- Ensure touch events can fire even though collision groups don't collide
	newBlock.CanTouch = true
	-- Assign block to Blocks collision group (after CanCollide/CanTouch)
	newBlock.CollisionGroup = "Blocks"

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
			-- Check if this block has a no-respawn tag
			if CollectionService:HasTag(block, "no-respawn") then
				return -- Don't store template or respawn no-respawn items
			end

			-- Mark this block as recently collected
			recentlyCollected[blockKey] = true

			-- Generate unique ID for template storage (separate from debounce key)
			local templateId = nextBlockId
			nextBlockId = nextBlockId + 1

			-- Get the count from the block's attribute, default to 1
			local count = block:GetAttribute("Count") or 1

			-- Ensure count is positive (handle edge case of negative values gracefully)
			if count <= 0 then
				count = 1
			end

			-- Try to add blocks to player inventory with capacity check (allows partial collection)
			local success, newCount, blocksAdded = DataManager.addBlocksToPlayer(player, count)
			if not success then
				-- Player cannot hold any of this block, remove from recently collected to allow retry
				recentlyCollected[blockKey] = nil
				return
			end

			local currentCount = newCount - blocksAdded -- Calculate what it was before adding

			-- Update collision group when BlockCount crosses 0 threshold
			if (currentCount == 0 and newCount > 0) or (currentCount > 0 and newCount == 0) then
				updatePlayerCollisionGroup(player)
			end

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
			for attributeName, _ in pairs(block:GetAttributes()) do
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
	-- Register collision groups FIRST (before setting any properties)
	PhysicsService:RegisterCollisionGroup("PlayersWithBlocks")
	PhysicsService:RegisterCollisionGroup("PlayersWithoutBlocks")
	PhysicsService:RegisterCollisionGroup("Blocks")
	PhysicsService:RegisterCollisionGroup("FakeFloor")

	-- Set collision relationships
	-- Players can pass through blocks (no physical collision) regardless of block count
	PhysicsService:CollisionGroupSetCollidable("PlayersWithBlocks", "Blocks", false)
	PhysicsService:CollisionGroupSetCollidable("PlayersWithoutBlocks", "Blocks", false)

	-- Players with blocks CAN stand on fake-floor
	PhysicsService:CollisionGroupSetCollidable("PlayersWithBlocks", "FakeFloor", true)
	-- Players without blocks CANNOT stand on fake-floor (pass through)
	PhysicsService:CollisionGroupSetCollidable("PlayersWithoutBlocks", "FakeFloor", false)
	-- Setup all existing blocks
	for _, block in ipairs(CollectionService:GetTagged("block")) do
		-- Ensure CanCollide is true first (needed for touch detection)
		if not block.CanCollide then
			block.CanCollide = true
		end
		block.CanTouch = true
		block.CollisionGroup = "Blocks"

		-- Ensure Count attribute exists (default to 1 if missing)
		if not block:GetAttribute("Count") then
			block:SetAttribute("Count", 1)
		end

		block.Touched:Connect(function(hit)
			onBlockTouched(block, hit)
		end)
	end

	-- Listen for new blocks being tagged
	CollectionService:GetInstanceAddedSignal("block"):Connect(function(block)
		-- Ensure CanCollide is true first (needed for touch detection)
		if not block.CanCollide then
			block.CanCollide = true
		end
		-- Ensure touch events can fire
		block.CanTouch = true
		-- Assign new blocks to Blocks collision group (after CanCollide/CanTouch)
		block.CollisionGroup = "Blocks"

		-- Ensure Count attribute exists (default to 1 if missing)
		if not block:GetAttribute("Count") then
			block:SetAttribute("Count", 1)
		end

		block.Touched:Connect(function(hit)
			onBlockTouched(block, hit)
		end)
	end)

	-- Setup collision groups for existing players
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			setCharacterCollisionGroup(player.Character, player)
		end
	end

	-- Listen for new players joining
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			-- Wait for HumanoidRootPart to ensure character is fully loaded
			character:WaitForChild("HumanoidRootPart", 10)
			setCharacterCollisionGroup(character, player)
		end)
	end)

	-- Clean up player cooldowns when players leave
	Players.PlayerRemoving:Connect(function(player)
		playerPlacementCooldowns[player.UserId] = nil
	end)

	-- Setup fake-floor parts
	for _, fakeFloorPart in ipairs(CollectionService:GetTagged("fake-floor")) do
		if fakeFloorPart:IsA("BasePart") then
			fakeFloorPart.CollisionGroup = "FakeFloor"
			fakeFloorPart.CanCollide = true
			fakeFloorPart.CanTouch = true
			fakeFloorPart.Touched:Connect(function(hit)
				onFakeFloorTouched(fakeFloorPart, hit)
			end)
		end
	end

	-- Listen for new fake-floor parts
	CollectionService:GetInstanceAddedSignal("fake-floor"):Connect(function(fakeFloorPart)
		if fakeFloorPart:IsA("BasePart") then
			fakeFloorPart.CollisionGroup = "FakeFloor"
			fakeFloorPart.CanCollide = true
			fakeFloorPart.CanTouch = true
			fakeFloorPart.Touched:Connect(function(hit)
				onFakeFloorTouched(fakeFloorPart, hit)
			end)
		end
	end)

	-- Monitor BlockCount changes and update collision groups
	for _, player in ipairs(Players:GetPlayers()) do
		player:GetAttributeChangedSignal("BlockCount"):Connect(function()
			updatePlayerCollisionGroup(player)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		player:GetAttributeChangedSignal("BlockCount"):Connect(function()
			updatePlayerCollisionGroup(player)
		end)
	end)

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
}
