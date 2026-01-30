-- Store system for handling store interactions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Ensure the module is loaded first (creates the event)
require(ReplicatedStorage:WaitForChild("Hello"))
-- Then get the event directly from ReplicatedStorage (same instance)
local openStoreEvent = ReplicatedStorage:WaitForChild("OpenStoreEvent")
local closeStoreEvent = ReplicatedStorage:WaitForChild("CloseStoreEvent")

-- Import DataManager for saving player data when store opens
local DataManager = require(game:GetService("ServerScriptService").DataManager)

-- Get the sell blocks event
local sellBlocksEvent = ReplicatedStorage:WaitForChild("SellBlocksEvent")

-- Track which players can trigger the store (prevents spam after closing)
local playerCooldowns = {}

-- Function to handle cashier trigger touching
local function onCashierTriggerTouched(_triggerPart, hit)
	-- Check if the hit part is part of a player's character
	local character = hit:FindFirstAncestorOfClass("Model")
	if character then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			-- Check if player is on cooldown (prevents immediate reopening after closing)
			if playerCooldowns[player.UserId] then
				return -- Player is still on cooldown, ignore the touch
			end

			-- Set cooldown to prevent immediate reopening
			playerCooldowns[player.UserId] = true

			-- Save all player data to database before opening store
			DataManager.savePlayerDataImmediately(player)

			-- Fire the remote event to open the store on the client
			openStoreEvent:FireClient(player)
		end
	end
end

-- Function to handle selling blocks
local function onSellBlocks(player, blocksToSell, totalCash)
	if not player then
		return false, "Player not found"
	end

	-- Double-check that the player has enough blocks
	local playerData = DataManager.getPlayerData(player)
	local currentBlocks = playerData.BlockCount or 0

	if currentBlocks < blocksToSell then
		return false, "Not enough blocks"
	end

	-- Calculate cash per block for the transaction
	local cashPerBlock = totalCash / blocksToSell

	-- Perform the transaction
	local success, newBlockCount, cashEarned = DataManager.sellBlocksFromPlayer(player, blocksToSell, cashPerBlock)

	if success then
		return true, newBlockCount, cashEarned
	else
		return false, "Transaction failed"
	end
end

-- Function to reset cooldown when store is closed (called from client)
local function onStoreClosed(player)
	if player then
		-- Remove cooldown after a short delay to prevent immediate reopening
		task.delay(5, function()
			playerCooldowns[player.UserId] = nil
		end)
	end
end

-- Initialize store system
local function init()
	-- Setup cashier trigger
	local cashierTrigger = workspace:WaitForChild("Store"):WaitForChild("CashierTrigger")
	cashierTrigger.Touched:Connect(function(hit)
		onCashierTriggerTouched(cashierTrigger, hit)
	end)

	-- Connect close store event
	closeStoreEvent.OnServerEvent:Connect(onStoreClosed)

	-- Connect sell blocks function
	sellBlocksEvent.OnServerInvoke = onSellBlocks
end

return {
	init = init,
}
