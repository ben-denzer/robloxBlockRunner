-- Store system for handling store interactions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

-- Ensure the module is loaded first (creates the event)
require(ReplicatedStorage:WaitForChild("Events"))
-- Then get the event directly from ReplicatedStorage (same instance)
local openStoreEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.OPEN_STORE)
local closeStoreEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.CLOSE_STORE)

-- Import DataManager for saving player data when store opens
local DataManager = require(game:GetService("ServerScriptService").DataManager)

-- Get the sell blocks event
local sellBlocksEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.SELL_BLOCKS)

-- Get the buy cart event
local buyCartEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.BUY_CART)

-- Configuration for valid sell transactions is now in Constants.SELL_BLOCKS_TRANSACTIONS

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
local function onSellBlocks(player, buttonIdentifier)
	if not player then
		return false, "Player not found"
	end

	-- Look up the transaction details from our authoritative configuration
	local transaction = Constants.SELL_BLOCKS_TRANSACTIONS[buttonIdentifier]
	if not transaction then
		return false, "Invalid transaction"
	end

	local blocksToSell = transaction.blocks
	local totalCash = transaction.cash

	-- Double-check that the player has enough blocks
	local playerData = DataManager.getPlayerData(player)
	local currentBlocks = playerData[Constants.PLAYER_ATTRIBUTES.BLOCK_COUNT] or 0

	if currentBlocks < blocksToSell then
		return false, "Not enough blocks"
	end

	-- Perform the transaction
	local success, newBlockCount, cashEarned = DataManager.sellBlocksFromPlayer(player, blocksToSell, totalCash)

	if success then
		return true, newBlockCount, cashEarned
	else
		return false, "Transaction failed"
	end
end

-- Function to check if player meets prerequisites for an item
local function checkPrerequisites(player, itemId)
	-- Get item data (cart or gravity coil)
	local itemData = Constants.TOOLS.CART_ITEMS[itemId] or Constants.TOOLS.GRAVITY_COILS[itemId]
	if not itemData then
		return false, "Invalid item"
	end

	-- Check if item has prerequisites
	local prerequisites = itemData.prerequisites or {}
	for _, prerequisiteId in ipairs(prerequisites) do
		local hasItem = DataManager.hasItemInInventory(player, prerequisiteId)
		if not hasItem then
			-- Get prerequisite item name for error message
			local prereqData = Constants.TOOLS.CART_ITEMS[prerequisiteId]
				or Constants.TOOLS.GRAVITY_COILS[prerequisiteId]
			local prereqName = prereqData and prereqData.displayName or prerequisiteId
			return false, "You must own '" .. prereqName .. "' first"
		end
	end

	return true -- All prerequisites met
end

-- Function to handle buying cart items
local function onBuyCart(player, cartItemId)
	print("onBuyCart", player, cartItemId)
	if not player then
		return false, "Player not found"
	end

	-- Validate that this is a valid cart item or gravity coil
	if not Constants.TOOLS.CART_ITEMS[cartItemId] and not Constants.TOOLS.GRAVITY_COILS[cartItemId] then
		return false, "Invalid item"
	end

	-- Check prerequisites before allowing purchase
	local prereqSuccess, prereqMessage = checkPrerequisites(player, cartItemId)
	if not prereqSuccess then
		return false, prereqMessage
	end

	-- Attempt to buy the cart item
	local success, result = DataManager.buyCartItem(player, cartItemId)

	if success then
		return true, result -- result contains new wagon size
	else
		return false, result -- result contains error message
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
	-- Setup all cashier triggers using tags
	local cashierTriggers = CollectionService:GetTagged(Constants.STORE_SYSTEM.TAGS.CASHIER_TRIGGER)

	for _, cashierTrigger in ipairs(cashierTriggers) do
		cashierTrigger.Touched:Connect(function(hit)
			onCashierTriggerTouched(cashierTrigger, hit)
		end)
	end

	-- Also listen for new cashier triggers that might be added later
	CollectionService:GetInstanceAddedSignal(Constants.STORE_SYSTEM.TAGS.CASHIER_TRIGGER)
		:Connect(function(cashierTrigger)
			cashierTrigger.Touched:Connect(function(hit)
				onCashierTriggerTouched(cashierTrigger, hit)
			end)
		end)

	-- Connect close store event
	closeStoreEvent.OnServerEvent:Connect(onStoreClosed)

	-- Connect sell blocks function
	sellBlocksEvent.OnServerInvoke = onSellBlocks

	-- Connect buy cart function
	buyCartEvent.OnServerInvoke = onBuyCart
end

return {
	init = init,
}
