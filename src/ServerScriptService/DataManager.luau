-- Data persistence system for player data
-- Designed to be modular and extensible for future data types

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Constants = require(game:GetService("ReplicatedStorage").Constants)

-- Configuration
local DATASTORE_NAME = "PlayerData"
local SAVE_INTERVAL = 60 -- Save every 60 seconds for active players
local MAX_RETRIES = 3
local RETRY_DELAY = 1

-- Data store instance
local dataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

-- Cache for player data (in-memory storage during session)
local playerDataCache = {}

-- Function to get default player data structure
local function getDefaultPlayerData()
	return {
		BlockCount = 0,
		Cash = 0,
		WagonSize = Constants.DEFAULT_WAGON_SIZE,
		-- Add other persistent data fields here as needed
		LastSave = os.time(),
	}
end

-- Function to safely save player data with retries
local function savePlayerData(player, data)
	local userId = tostring(player.UserId)

	-- Skip DataStore access entirely in Studio
	if game:GetService("RunService"):IsStudio() then
		print("Studio detected - simulating successful save for player " .. player.Name)
		playerDataCache[userId] = table.clone(data)
		playerDataCache[userId].LastSave = os.time()
		return true
	end

	local success = false
	local attempts = 0

	while not success and attempts < MAX_RETRIES do
		attempts = attempts + 1
		local s, errorMessage = pcall(function()
			dataStore:SetAsync(userId, data)
		end)

		if s then
			playerDataCache[userId] = table.clone(data)
			playerDataCache[userId].LastSave = os.time()
		else
			warn(
				"Failed to save data for player "
					.. player.Name
					.. " (attempt "
					.. attempts
					.. "): "
					.. tostring(errorMessage)
			)
			if attempts < MAX_RETRIES then
				task.wait(RETRY_DELAY)
			end
		end
	end

	return success
end

-- Function to safely load player data with retries
local function loadPlayerData(player)
	local userId = tostring(player.UserId)

	-- Skip DataStore access entirely in Studio
	if game:GetService("RunService"):IsStudio() then
		local data = getDefaultPlayerData()
		print("Studio detected - using default data for player " .. player.Name)
		playerDataCache[userId] = table.clone(data)
		playerDataCache[userId].LastSave = os.time()
		return data
	end

	local success = false
	local data = nil
	local attempts = 0

	while not success and attempts < MAX_RETRIES do
		attempts = attempts + 1
		local s, errorMessage = pcall(function()
			data = dataStore:GetAsync(userId)
		end)

		if not s then
			warn(
				"Failed to load data for player "
					.. player.Name
					.. " (attempt "
					.. attempts
					.. "): "
					.. tostring(errorMessage)
			)
			if attempts < MAX_RETRIES then
				task.wait(RETRY_DELAY)
			end
		end
	end

	-- If loading failed or no data exists, use defaults
	if not success or not data then
		data = getDefaultPlayerData()
	end

	-- Cache the loaded data
	playerDataCache[userId] = table.clone(data)
	playerDataCache[userId].LastSave = os.time()

	return data
end

-- Function to get player data (from cache if available)
local function getPlayerData(player)
	local userId = tostring(player.UserId)
	return playerDataCache[userId] or loadPlayerData(player)
end

-- Function to update specific player data
local function updatePlayerData(player, key, value)
	local userId = tostring(player.UserId)
	local data = getPlayerData(player)

	-- Update the specific field
	data[key] = value
	playerDataCache[userId] = table.clone(data)

	-- Update the player's attribute so client-side listeners work
	player:SetAttribute(key, value)

	-- Data will be saved during periodic saves, player leave, or server shutdown
	-- No immediate save to avoid excessive database calls during rapid gameplay
end

-- Function to update player cash with immediate save to database
local function updatePlayerCash(player, newCash)
	local userId = tostring(player.UserId)
	local data = getPlayerData(player)

	-- Update the cash field
	data.Cash = newCash
	playerDataCache[userId] = table.clone(data)

	-- Update the player's attribute so client-side listeners work
	player:SetAttribute("Cash", newCash)

	-- Save immediately to database (unlike other data which saves periodically)
	savePlayerData(player, data)
end

-- Function to add blocks to player inventory with wagon capacity check
-- Returns: success (boolean), newCount (number), blocksAdded (number)
local function addBlocksToPlayer(player, count)
	local userId = tostring(player.UserId)
	local data = getPlayerData(player)

	local currentCount = data.BlockCount or 0
	local wagonSize = data.WagonSize or Constants.DEFAULT_WAGON_SIZE

	-- Calculate how many blocks we can actually add without exceeding capacity
	local availableSpace = wagonSize - currentCount
	local blocksToAdd = math.min(count, availableSpace)

	-- If no space available, return false
	if blocksToAdd <= 0 then
		return false, currentCount, 0
	end

	-- Update the block count with the actual amount that fits
	local newCount = currentCount + blocksToAdd
	data.BlockCount = newCount
	playerDataCache[userId] = table.clone(data)
	player:SetAttribute("BlockCount", newCount)

	return true, newCount, blocksToAdd
end

-- Function to save all cached data (called on server shutdown or periodically)
local function saveAllPlayerData()
	-- Skip saving in Studio
	if game:GetService("RunService"):IsStudio() then
		print("Studio detected - skipping data save")
		return
	end

	for userId, data in pairs(playerDataCache) do
		local player = Players:GetPlayerByUserId(tonumber(userId))
		if player then
			savePlayerData(player, data)
		end
	end
end

-- Function to handle player joining
local function onPlayerAdded(player)
	local data = loadPlayerData(player)

	-- Set initial attributes from loaded data
	for key, value in pairs(data) do
		if key ~= "LastSave" then -- Don't set LastSave as an attribute
			player:SetAttribute(key, value)
		end
	end
end

-- Function to handle player leaving
local function onPlayerRemoving(player)
	local userId = tostring(player.UserId)
	local data = playerDataCache[userId]

	if data then
		-- Update data with current attribute values before saving
		for key, _ in pairs(data) do
			if key ~= "LastSave" then
				data[key] = player:GetAttribute(key) or data[key]
			end
		end

		savePlayerData(player, data)
		playerDataCache[userId] = nil
	end
end

-- Function to initialize the data manager
local function init()
	-- Connect player events
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Periodic save for active players (skip in Studio)
	if not game:GetService("RunService"):IsStudio() then
		task.spawn(function()
			while true do
				task.wait(SAVE_INTERVAL)
				saveAllPlayerData()
			end
		end)

		-- Save on server shutdown
		game:BindToClose(function()
			saveAllPlayerData()
		end)
	end

	if game:GetService("RunService"):IsStudio() then
		print("Studio detected - skipping data save")
		return
	end
end

return {
	init = init,
	getPlayerData = getPlayerData,
	updatePlayerData = updatePlayerData,
	updatePlayerCash = updatePlayerCash,
	addBlocksToPlayer = addBlocksToPlayer,
	savePlayerData = savePlayerData,
	loadPlayerData = loadPlayerData,
	getDefaultPlayerData = getDefaultPlayerData,
}
