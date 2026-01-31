-- Cash collection and respawning system

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local DataManager = require(game:GetService("ServerScriptService").DataManager)
local Constants = require(game:GetService("ReplicatedStorage").Constants)

-- Track recently collected cash to prevent double collection
local recentlyCollected = {}

-- Store cash templates for respawning
local cashTemplates = {}
local nextCashId = 1

-- Store cash that failed to respawn due to players being in the way
local respawnStorage = {}

-- Function to create a cash part from template
local function createCashFromTemplate(template)
	local newCash = Instance.new("Part")
	newCash.Size = template.Size
	newCash.Position = template.Position
	newCash.Anchored = template.Anchored
	newCash.CanCollide = template.CanCollide
	newCash.Material = template.Material
	newCash.Color = template.Color
	newCash.Name = template.Name
	newCash.Parent = template.Parent

	-- Copy attributes
	for attributeName, attributeValue in pairs(template.Attributes) do
		newCash:SetAttribute(attributeName, attributeValue)
	end

	-- Ensure Count attribute exists (default to 100 if missing)
	if not newCash:GetAttribute("Count") then
		newCash:SetAttribute("Count", Constants.CASH_SYSTEM.DEFAULT_CASH_COUNT)
	end

	-- Copy all stored children (decals, BillboardGui, etc.) to the new cash part
	for _, child in ipairs(template.Children) do
		local clonedChild = child:Clone()
		clonedChild.Parent = newCash
	end

	-- Add the "cash" tag
	CollectionService:AddTag(newCash, Constants.CASH_SYSTEM.TAGS.CASH)

	-- Set properties for touch detection (no collision, only touch)
	newCash.CanCollide = false
	newCash.CanTouch = true

	return newCash
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

-- Function to periodically try respawning stored cash
local function tryRespawnStoredCash()
	for storageId, template in pairs(respawnStorage) do
		local playerNearby = isPlayerNearPosition(template.Position, Constants.CASH_SYSTEM.PLAYER_NEAR_RADIUS)

		if not playerNearby then
			-- Safe to respawn now
			createCashFromTemplate(template)
			respawnStorage[storageId] = nil
		end
	end
end

-- Function to handle cash collection
local function onCashTouched(cashPart, hit)
	-- Use cash position as unique identifier for debounce (since cash will be destroyed)
	local cashKey = tostring(cashPart.Position)

	-- Check if this cash was recently collected to prevent double collection
	if recentlyCollected[cashKey] then
		return
	end

	-- Check if the hit part is part of a player's character
	local character = hit:FindFirstAncestorOfClass("Model")
	if character then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			-- Check if this cash has a no-respawn tag
			if CollectionService:HasTag(cashPart, Constants.CASH_SYSTEM.TAGS.NO_RESPAWN) then
				return -- Don't store template or respawn no-respawn items
			end

			-- Mark this cash as recently collected
			recentlyCollected[cashKey] = true

			-- Generate unique ID for template storage (separate from debounce key)
			local templateId = nextCashId
			nextCashId = nextCashId + 1

			-- Get the count from the cash's attribute, default to 100
			local count = cashPart:GetAttribute("Count") or Constants.CASH_SYSTEM.DEFAULT_CASH_COUNT

			-- Ensure count is positive (handle edge case of negative values gracefully)
			if count <= 0 then
				count = Constants.CASH_SYSTEM.DEFAULT_CASH_COUNT
			end

			-- Add cash to player (cash has unlimited capacity, unlike blocks)
			local currentCash = player:GetAttribute("Cash") or 0
			local newCash = currentCash + count
			DataManager.updatePlayerCash(player, newCash)

			-- Store template for respawning
			local template = {
				Size = cashPart.Size,
				Position = cashPart.Position,
				Anchored = cashPart.Anchored,
				CanCollide = cashPart.CanCollide,
				Material = cashPart.Material,
				Color = cashPart.Color,
				Name = cashPart.Name,
				Parent = cashPart.Parent,
				Children = {}, -- Store cloned children for respawning
				Attributes = {},
			}

			-- Store all attributes
			for attributeName, _ in pairs(cashPart:GetAttributes()) do
				template.Attributes[attributeName] = cashPart:GetAttribute(attributeName)
			end

			-- Clone and store all children (decals, BillboardGui, etc.) for respawning
			for _, child in ipairs(cashPart:GetChildren()) do
				local clonedChild = child:Clone()
				table.insert(template.Children, clonedChild)
			end

			cashTemplates[templateId] = template

			-- Destroy the cash
			cashPart:Destroy()

			-- Respawn the cash with retry logic if players are in the way
			local function tryRespawn(attemptNumber)
				if not cashTemplates[templateId] then
					return
				end

				local playerNearby = isPlayerNearPosition(template.Position, Constants.CASH_SYSTEM.PLAYER_NEAR_RADIUS)

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
						createCashFromTemplate(template)
					end
					cashTemplates[templateId] = nil
				end
			end

			-- Start the respawn process after 45 seconds
			task.delay(45, function()
				tryRespawn(1)
			end)

			-- Clear the debounce after a short delay
			task.delay(0.1, function()
				recentlyCollected[cashKey] = nil
			end)
		end
	end
end

-- Initialize cash system
local function init()
	-- Setup all existing cash parts
	for _, cashPart in ipairs(CollectionService:GetTagged(Constants.CASH_SYSTEM.TAGS.CASH)) do
		-- Ensure Count attribute exists (default to 100 if missing)
		if not cashPart:GetAttribute("Count") then
			cashPart:SetAttribute("Count", Constants.CASH_SYSTEM.DEFAULT_CASH_COUNT)
		end

		-- Ensure touch detection works (no collision, only touch)
		cashPart.CanCollide = false
		cashPart.CanTouch = true

		cashPart.Touched:Connect(function(hit)
			onCashTouched(cashPart, hit)
		end)
	end

	-- Listen for new cash parts being tagged
	CollectionService:GetInstanceAddedSignal(Constants.CASH_SYSTEM.TAGS.CASH):Connect(function(cashPart)
		-- Ensure Count attribute exists (default to 100 if missing)
		if not cashPart:GetAttribute("Count") then
			cashPart:SetAttribute("Count", Constants.CASH_SYSTEM.DEFAULT_CASH_COUNT)
		end

		-- Ensure touch detection works (no collision, only touch)
		cashPart.CanCollide = false
		cashPart.CanTouch = true

		cashPart.Touched:Connect(function(hit)
			onCashTouched(cashPart, hit)
		end)
	end)

	-- Start periodic check for stored cash every 60 seconds
	task.spawn(function()
		while true do
			task.wait(60) -- Wait 60 seconds
			tryRespawnStoredCash()
		end
	end)
end

return {
	init = init,
}
