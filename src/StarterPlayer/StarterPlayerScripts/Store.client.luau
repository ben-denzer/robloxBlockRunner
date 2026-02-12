-- Store GUI functionality
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Utils = require(ReplicatedStorage:WaitForChild("Utils"))
-- Store the original walk speed when the store opens
local originalWalkSpeed = 16 -- Default Roblox walk speed

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local UI_ELEMENTS = Constants.UI_ELEMENTS
local StoreUIManager = require(ReplicatedStorage:WaitForChild("StoreUIManager"))

-- Initialize the UI manager with dependencies
StoreUIManager.init({
	playerGui = playerGui,
	UI_ELEMENTS = UI_ELEMENTS,
})

-- Track if buttons have been connected
local buttonsConnected = false

-- Transparency values for disabled buttons
local DISABLED_TRANSPARENCY = 0.7
local ENABLED_TRANSPARENCY = 0

-- Ensure the module is loaded first (creates the event)
require(ReplicatedStorage:WaitForChild("Events"))
-- Then get the event directly from ReplicatedStorage (same instance as server)
local openStoreEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.OPEN_STORE)
local closeStoreEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.CLOSE_STORE)
local sellBlocksEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.SELL_BLOCKS)
local buyCartEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.BUY_CART)

-- Handle CloseButton click to disable StoreGui
local function onCloseButtonClicked()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		storeGui.Enabled = false
	end

	-- Unfreeze the player
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = originalWalkSpeed
			humanoid.PlatformStand = false
		end
	end

	-- Notify server that store was closed (resets cooldown after delay)
	closeStoreEvent:FireServer()
end

-- Function to update sell button states based on player's block count
local function updateSellButtonStates()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if not storeGui then
		return
	end

	local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
	if not sellFrame then
		return
	end

	local sellBlocksFrame = sellFrame:FindFirstChild(UI_ELEMENTS.FRAMES.SELL_BLOCKS)
	if not sellBlocksFrame then
		return
	end

	-- Get player's current block count
	local playerBlockCount = player:GetAttribute("BlockCount") or 0

	-- Get sell blocks transactions from constants
	local sellBlocksTransactions = Constants.SELL_BLOCKS_TRANSACTIONS

	-- Find all buttons tagged "sell-blocks-button"
	local sellButtons = {}
	for _, child in ipairs(sellBlocksFrame:GetChildren()) do
		if child:IsA("ImageButton") and child:HasTag(UI_ELEMENTS.TAGS.SELL_BLOCKS_BUTTON) then
			table.insert(sellButtons, child)
		end
	end

	-- Update each button's state
	for _, button in ipairs(sellButtons) do
		local transactionData = sellBlocksTransactions[button.Name]
		if transactionData then
			local blocksRequired = transactionData.blocks
			local hasEnoughBlocks = playerBlockCount >= blocksRequired

			-- Update visual state
			local imageLabel = button:FindFirstChild(UI_ELEMENTS.ELEMENTS.IMAGE_LABEL)
			local blocksText = button:FindFirstChild(UI_ELEMENTS.ELEMENTS.BLOCKS_TEXT)
			local cashText = button:FindFirstChild(UI_ELEMENTS.ELEMENTS.CASH_TEXT)

			local transparency = hasEnoughBlocks and ENABLED_TRANSPARENCY or DISABLED_TRANSPARENCY

			if imageLabel then
				imageLabel.ImageTransparency = transparency
			end
			if blocksText then
				blocksText.TextTransparency = transparency
				blocksText.Text = tostring(blocksRequired) .. " Blocks"
			end
			if cashText then
				cashText.TextTransparency = transparency
				cashText.Text = "$" .. Utils.formatCash(transactionData.cash)
			end

			-- Store the enabled state for click handling
			button:SetAttribute(UI_ELEMENTS.ATTRIBUTES.ENABLED, hasEnoughBlocks)
		end
	end
end

local function createModalBackdrop()
	local modalBackdrop = Instance.new("TextButton")
	modalBackdrop.Name = UI_ELEMENTS.ELEMENTS.MODAL_BACKDROP
	modalBackdrop.Size = UDim2.fromScale(1, 1)
	modalBackdrop.Position = UDim2.fromScale(0, 0)
	modalBackdrop.BackgroundTransparency = 1
	modalBackdrop.Text = ""
	modalBackdrop.ZIndex = 10 -- Above content, below error frame
	return modalBackdrop
end

-- Function to show error frame when disabled button is clicked
local function showErrorFrame(errorMessage)
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if not storeGui then
		return
	end

	local errorFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.ERROR)
	if not errorFrame then
		return
	end

	local dynamicText = errorFrame:FindFirstChild(UI_ELEMENTS.ELEMENTS.DYNAMIC_TEXT)
	if dynamicText then
		dynamicText.Text = errorMessage
	end

	-- Create or show modal backdrop to block all interaction
	local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
	local shopFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)

	if not sellFrame or not shopFrame then
		return
	end

	local visibleFrame = sellFrame.Visible and sellFrame or shopFrame

	if visibleFrame then
		local modalBackdrop = visibleFrame:FindFirstChild(UI_ELEMENTS.ELEMENTS.MODAL_BACKDROP)
		if not modalBackdrop then
			modalBackdrop = createModalBackdrop()
			modalBackdrop.Parent = visibleFrame
			modalBackdrop.MouseButton1Click:Connect(function() end)
		end
		modalBackdrop.Visible = true
	end

	errorFrame.Visible = true
end

-- Function to hide error frame
local function hideErrorFrame()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if not storeGui then
		return
	end

	local errorFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.ERROR)
	if errorFrame then
		errorFrame.Visible = false

		-- Hide modal backdrop to restore interaction
		local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		local shopFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)

		if sellFrame then
			local modalBackdrop = sellFrame:FindFirstChild(UI_ELEMENTS.ELEMENTS.MODAL_BACKDROP)
			if modalBackdrop then
				modalBackdrop.Visible = false
			end
		end
		if shopFrame then
			local modalBackdrop = shopFrame:FindFirstChild(UI_ELEMENTS.ELEMENTS.MODAL_BACKDROP)
			if modalBackdrop then
				modalBackdrop.Visible = false
			end
		end
	end
end

-- Function to get owned items from client attribute
local function getOwnedItems()
	local ownedItemsJson = player:GetAttribute("OwnedItems")
	if ownedItemsJson then
		local success, ownedItems = pcall(function()
			return game:GetService("HttpService"):JSONDecode(ownedItemsJson)
		end)
		if success then
			return ownedItems
		end
	end
	return {}
end

-- Function to update cart button states based on ownership and cash
local function updateCartButtonStates()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if not storeGui then
		return
	end

	local shopFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)
	if not shopFrame then
		return
	end

	local cartFrame = shopFrame:FindFirstChild(UI_ELEMENTS.FRAMES.BUY_TOOLS)
	if not cartFrame then
		return
	end

	-- Get player's current cash and owned items
	local playerCash = player:GetAttribute("Cash") or 0
	local ownedItems = getOwnedItems()

	-- Get constants for cart items
	local cartItems = Constants.TOOLS.CART_ITEMS

	-- Find all cart buttons
	local cartButtons = {}
	for _, child in ipairs(cartFrame:GetChildren()) do
		if child:IsA("ImageButton") and child:HasTag(UI_ELEMENTS.TAGS.BUY_CART_BUTTON) then
			table.insert(cartButtons, child)
		end
	end

	-- Update each cart button
	for _, button in ipairs(cartButtons) do
		local cartId = button.Name -- Should match Constants.TOOLS.CART_ITEMS keys
		local cartData = cartItems[cartId]

		if cartData then
			local price = cartData.price

			local hasEnoughCash = playerCash >= price
			local alreadyOwns = ownedItems[cartId] == true
			local canPurchase = hasEnoughCash and not alreadyOwns

			-- Update visual state
			local imageLabel = button:FindFirstChild(UI_ELEMENTS.ELEMENTS.IMAGE_LABEL)
			local nameText = button:FindFirstChild(UI_ELEMENTS.ELEMENTS.NAME_TEXT)
			local priceText = button:FindFirstChild(UI_ELEMENTS.ELEMENTS.CASH_TEXT)
			local descriptionText = button:FindFirstChild(UI_ELEMENTS.ELEMENTS.DESCRIPTION_TEXT)

			local transparency = canPurchase and ENABLED_TRANSPARENCY or DISABLED_TRANSPARENCY

			if imageLabel then
				imageLabel.ImageTransparency = transparency
				imageLabel.Image = alreadyOwns and UI_ELEMENTS.ASSETS.OWNED_ITEM_IMAGE or cartData.image
			end
			if nameText then
				nameText.TextTransparency = transparency
			end
			if priceText then
				priceText.TextTransparency = transparency
			end
			if descriptionText then
				descriptionText.TextTransparency = transparency
			end

			-- Store the enabled state for click handling
			button:SetAttribute(UI_ELEMENTS.ATTRIBUTES.ENABLED, canPurchase)

			-- Update text content
			if nameText then
				nameText.Text = cartData.displayName
			end
			if priceText then
				priceText.Text = "$" .. Utils.formatCash(price)
			end
			if descriptionText then
				descriptionText.Text = cartData.description
			end
		end
	end
end

-- Function to update gravity coil button states based on ownership and cash
local function updateGravityCoilButtonStates()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if not storeGui then
		return
	end

	local shopFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)
	if not shopFrame then
		return
	end

	local cartFrame = shopFrame:FindFirstChild(UI_ELEMENTS.FRAMES.BUY_TOOLS)
	if not cartFrame then
		return
	end

	-- Get player's current cash and owned items
	local playerCash = player:GetAttribute("Cash") or 0
	local ownedItems = getOwnedItems()

	-- Get constants for gravity coil items
	local gravityCoilItems = Constants.TOOLS.GRAVITY_COILS

	-- Find all gravity coil buttons
	local gravityCoilButtons = {}
	for _, child in ipairs(cartFrame:GetChildren()) do
		if child:IsA("ImageButton") and child:HasTag(UI_ELEMENTS.TAGS.BUY_GRAVITY_COIL_BUTTON) then
			table.insert(gravityCoilButtons, child)
		end
	end

	-- Update each gravity coil button
	for _, button in ipairs(gravityCoilButtons) do
		local coilId = button.Name -- Should match Constants.TOOLS.GRAVITY_COILS keys
		local coilData = gravityCoilItems[coilId]

		if coilData then
			local price = coilData.price

			local hasEnoughCash = playerCash >= price
			local alreadyOwns = ownedItems[coilId] == true
			local canPurchase = hasEnoughCash and not alreadyOwns

			-- Update visual state
			local imageLabel = button:FindFirstChild(UI_ELEMENTS.ELEMENTS.IMAGE_LABEL)
			local nameText = button:FindFirstChild(UI_ELEMENTS.ELEMENTS.NAME_TEXT)
			local priceText = button:FindFirstChild(UI_ELEMENTS.ELEMENTS.CASH_TEXT)
			local descriptionText = button:FindFirstChild(UI_ELEMENTS.ELEMENTS.DESCRIPTION_TEXT)

			local transparency = canPurchase and ENABLED_TRANSPARENCY or DISABLED_TRANSPARENCY

			if imageLabel then
				imageLabel.ImageTransparency = transparency
				imageLabel.Image = alreadyOwns and UI_ELEMENTS.ASSETS.OWNED_ITEM_IMAGE or coilData.image
			end
			if nameText then
				nameText.TextTransparency = transparency
			end
			if priceText then
				priceText.TextTransparency = transparency
			end
			if descriptionText then
				descriptionText.TextTransparency = transparency
			end

			-- Store the enabled state for click handling
			button:SetAttribute(UI_ELEMENTS.ATTRIBUTES.ENABLED, canPurchase)

			-- Update text content
			if nameText then
				nameText.Text = coilData.displayName
			end
			if priceText then
				priceText.Text = "$" .. Utils.formatCash(price)
			end
			if descriptionText then
				descriptionText.Text = coilData.description
			end
		end
	end
end

-- Function to show confirmation screen for transactions (buying or selling)
local function showConfirmationScreen(button, transactionType)
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if not storeGui then
		return
	end

	local confirmationFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.CONFIRMATION)
	if not confirmationFrame then
		return
	end

	local dynamicText = confirmationFrame:FindFirstChild(UI_ELEMENTS.ELEMENTS.DYNAMIC_TEXT)
	if not dynamicText then
		return
	end

	-- Update confirmation text based on transaction type
	if transactionType == "sell" then
		-- Handle selling blocks
		local transactionData = Constants.SELL_BLOCKS_TRANSACTIONS[button.Name]

		if not transactionData then
			return
		end

		local blocksToSell = transactionData.blocks
		local cashReward = transactionData.cash

		dynamicText.Text = string.format("Sell %d blocks for $%s?", blocksToSell, Utils.formatCash(cashReward))
	elseif transactionType == "buy" then
		-- Handle buying items (carts, gravity coils, etc.)
		local itemName = button.Name
		local itemData = Constants.TOOLS.CART_ITEMS[itemName] or Constants.TOOLS.GRAVITY_COILS[itemName]

		if not itemData then
			return
		end

		local price = itemData.price
		local displayName = itemData.displayName

		dynamicText.Text = string.format("Purchase %s for $%s?", displayName, Utils.formatCash(price))
	else
		-- Fallback for unknown transaction types
		dynamicText.Text = "Are you sure you want to proceed with this transaction?"
	end

	-- Store transaction details for later use when confirming
	confirmationFrame:SetAttribute("PendingButton", button.Name)
	confirmationFrame:SetAttribute("TransactionType", transactionType)

	-- Determine which frame to apply modal backdrop to
	local targetFrame = nil
	if transactionType == "sell" then
		targetFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
	elseif transactionType == "buy" then
		targetFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)
	end

	if targetFrame then
		local modalBackdrop = targetFrame:FindFirstChild(UI_ELEMENTS.ELEMENTS.MODAL_BACKDROP)
		if not modalBackdrop then
			modalBackdrop = createModalBackdrop()
			modalBackdrop.Parent = targetFrame
			modalBackdrop.MouseButton1Click:Connect(function() end)
		end
		modalBackdrop.Visible = true
	end

	confirmationFrame.Visible = true
end

-- Function to handle cart button clicks (now shows confirmation)
local function onCartButtonClicked(button)
	local isEnabled = button:GetAttribute(UI_ELEMENTS.ATTRIBUTES.ENABLED)
	if isEnabled then
		-- Show confirmation screen instead of buying directly
		showConfirmationScreen(button, "buy")
	else
		-- Check why the button is disabled
		local ownedItems = getOwnedItems()
		local cartId = button.Name

		if ownedItems[cartId] then
			showErrorFrame("You already own this cart")
		else
			showErrorFrame("You cannot purchase this cart right now")
		end
	end
end

-- Function to handle gravity coil button clicks (shows confirmation or error)
local function onGravityCoilButtonClicked(button)
	local isEnabled = button:GetAttribute(UI_ELEMENTS.ATTRIBUTES.ENABLED)
	if isEnabled then
		-- Show confirmation screen instead of buying directly
		showConfirmationScreen(button, "buy")
	else
		-- Check why the button is disabled
		local ownedItems = getOwnedItems()
		local coilId = button.Name

		if ownedItems[coilId] then
			showErrorFrame("You already own this gravity coil")
		else
			showErrorFrame("You cannot purchase this gravity coil right now")
		end
	end
end

-- Function to hide confirmation screen
local function hideConfirmationScreen()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if not storeGui then
		return
	end

	local confirmationFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.CONFIRMATION)
	if confirmationFrame then
		confirmationFrame.Visible = false
		confirmationFrame:SetAttribute("PendingButton", nil)
		confirmationFrame:SetAttribute("TransactionType", nil)
	end

	-- Hide modal backdrop from both sell and shop frames to restore interaction
	local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
	local shopFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)

	if sellFrame then
		local modalBackdrop = sellFrame:FindFirstChild(UI_ELEMENTS.ELEMENTS.MODAL_BACKDROP)
		if modalBackdrop then
			modalBackdrop.Visible = false
		end
	end

	if shopFrame then
		local modalBackdrop = shopFrame:FindFirstChild(UI_ELEMENTS.ELEMENTS.MODAL_BACKDROP)
		if modalBackdrop then
			modalBackdrop.Visible = false
		end
	end
end

-- Function to handle confirmation of transaction (buying or selling)
local function onConfirmTransaction()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if not storeGui then
		return
	end

	local confirmationFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.CONFIRMATION)
	if not confirmationFrame then
		return
	end

	local buttonIdentifier = confirmationFrame:GetAttribute("PendingButton")
	local transactionType = confirmationFrame:GetAttribute("TransactionType")
	if not buttonIdentifier or not transactionType then
		return
	end

	-- Hide confirmation screen first
	hideConfirmationScreen()

	-- Proceed with the actual transaction based on type
	if transactionType == "sell" then
		-- Handle block sale
		local success, result1, _ = sellBlocksEvent:InvokeServer(buttonIdentifier)

		if success then
			-- Transaction successful, update button states
			updateSellButtonStates()
		else
			-- Show error message from server
			showErrorFrame(result1 or "Transaction failed")
		end
	elseif transactionType == "buy" then
		-- Handle item purchase
		local success, result = buyCartEvent:InvokeServer(buttonIdentifier)

		if success then
			-- Purchase successful, update button states
			updateCartButtonStates()
			updateGravityCoilButtonStates()
		else
			-- Show error message from server
			showErrorFrame(result or "Purchase failed")
		end
	else
		-- Unknown transaction type
		showErrorFrame("Unknown transaction type")
	end
end

-- Function to handle canceling the block sale
local function onCancelSellBlocks()
	-- Simply hide the confirmation screen
	hideConfirmationScreen()
end

-- Function to handle sell button clicks (now shows confirmation)
local function onSellBlocksButtonClicked(button)
	local isEnabled = button:GetAttribute(UI_ELEMENTS.ATTRIBUTES.ENABLED)
	if isEnabled then
		-- Show confirmation screen instead of selling directly
		showConfirmationScreen(button, "sell")
	else
		-- Show error frame for disabled button
		showErrorFrame("You do not have enough blocks to complete this transaction")
	end
end

openStoreEvent.OnClientEvent:Connect(function()
	-- Debug: Check if StoreGui exists
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if not storeGui then
		warn("StoreGui not found in PlayerGui! Contents:", playerGui:GetChildren())
		return
	end

	-- Connect buttons if not already connected
	if not buttonsConnected then
		local buyOrSellMenu = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.BUY_OR_SELL)
		if buyOrSellMenu then
			local closeButton = buyOrSellMenu:FindFirstChild(UI_ELEMENTS.BUTTONS.CLOSE)
			if closeButton then
				closeButton.MouseButton1Click:Connect(onCloseButtonClicked)
			else
				print("Close button not found")
			end

			-- Connect SellButton and ShopButton click events
			local sellButton = buyOrSellMenu:FindFirstChild(UI_ELEMENTS.BUTTONS.SELL)
			local shopButton = buyOrSellMenu:FindFirstChild(UI_ELEMENTS.BUTTONS.SHOP)

			if sellButton then
				sellButton.MouseButton1Click:Connect(function()
					StoreUIManager.showSellFrame(updateSellButtonStates)
				end)
			end

			if shopButton then
				shopButton.MouseButton1Click:Connect(function()
					StoreUIManager.showShopFrame(function()
						updateCartButtonStates()
						updateGravityCoilButtonStates()
					end)
				end)
			end
		end

		-- Connect BackButton in Sell frame
		local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		if sellFrame then
			local backButton = sellFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.BACK)
			if backButton then
				backButton.MouseButton1Click:Connect(StoreUIManager.showBuyOrSellFrame)
			end
		end

		-- Connect BackButton in Shop frame
		local shopFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)
		if shopFrame then
			local backButton = shopFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.BACK)
			if backButton then
				backButton.MouseButton1Click:Connect(StoreUIManager.showBuyOrSellFrame)
			end
		end

		-- Connect sell button click events
		local sellFrameLocal = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		if sellFrameLocal then
			local sellBlocksFrame = sellFrameLocal:FindFirstChild(UI_ELEMENTS.FRAMES.SELL_BLOCKS)
			if sellBlocksFrame then
				-- Connect all sell buttons
				for _, child in ipairs(sellBlocksFrame:GetChildren()) do
					if child:IsA("ImageButton") and child:HasTag(UI_ELEMENTS.TAGS.SELL_BLOCKS_BUTTON) then
						child.MouseButton1Click:Connect(function()
							onSellBlocksButtonClicked(child)
						end)
					end
				end
			end
		end

		-- Connect error frame cancel button
		local errorFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.ERROR)
		if errorFrame then
			local cancelButton = errorFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.CANCEL)
			if cancelButton then
				cancelButton.MouseButton1Click:Connect(hideErrorFrame)
			end
		end

		-- Connect confirmation frame buttons
		local confirmationFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.CONFIRMATION)
		if confirmationFrame then
			local confirmButton = confirmationFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.CONFIRM)
			local cancelButton = confirmationFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.CANCEL)

			if confirmButton then
				confirmButton.MouseButton1Click:Connect(onConfirmTransaction)
			end
			if cancelButton then
				cancelButton.MouseButton1Click:Connect(onCancelSellBlocks)
			end
		end

		-- Connect cart button click events
		local shopFrameConnect = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)
		if shopFrameConnect then
			local cartFrame = shopFrameConnect:FindFirstChild(UI_ELEMENTS.FRAMES.BUY_TOOLS)
			if cartFrame then
				-- Connect all cart buttons
				for _, child in ipairs(cartFrame:GetChildren()) do
					if child:IsA("ImageButton") and child:HasTag(UI_ELEMENTS.TAGS.BUY_CART_BUTTON) then
						child.MouseButton1Click:Connect(function()
							onCartButtonClicked(child)
						end)
					end
				end

				-- Connect all gravity coil buttons
				for _, child in ipairs(cartFrame:GetChildren()) do
					if child:IsA("ImageButton") and child:HasTag(UI_ELEMENTS.TAGS.BUY_GRAVITY_COIL_BUTTON) then
						child.MouseButton1Click:Connect(function()
							onGravityCoilButtonClicked(child)
						end)
					end
				end
			end
		end

		buttonsConnected = true
	end

	-- Connect to BlockCount attribute changes to update button states
	player:GetAttributeChangedSignal("BlockCount"):Connect(function()
		-- Only update if SellBlocksFrame is currently visible
		local storeGuiLocal = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
		if storeGuiLocal and storeGuiLocal.Enabled then
			local sellFrame = storeGuiLocal:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
			if sellFrame then
				local sellBlocksFrame = sellFrame:FindFirstChild(UI_ELEMENTS.FRAMES.SELL_BLOCKS)
				if sellBlocksFrame and sellBlocksFrame.Visible then
					updateSellButtonStates()
				end
			end
		end
	end)

	-- Connect to Cash attribute changes to update cart button states
	player:GetAttributeChangedSignal("Cash"):Connect(function()
		-- Only update if Shop frame is currently visible
		local storeGuiLocal = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
		if storeGuiLocal and storeGuiLocal.Enabled then
			local shopFrameLocal = storeGuiLocal:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)
			if shopFrameLocal and shopFrameLocal.Visible then
				updateCartButtonStates()
				updateGravityCoilButtonStates()
			end
		end
	end)

	-- Connect to OwnedItems attribute changes to update cart button states
	player:GetAttributeChangedSignal("OwnedItems"):Connect(function()
		-- Only update if Shop frame is currently visible
		local storeGuiLocal = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
		if storeGuiLocal and storeGuiLocal.Enabled then
			local shopFrameLocal = storeGuiLocal:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)
			if shopFrameLocal and shopFrameLocal.Visible then
				updateCartButtonStates()
				updateGravityCoilButtonStates()
			end
		end
	end)

	-- Initialize sell tabs
	StoreUIManager.initializeSellTabs()

	-- Initialize shop tabs
	StoreUIManager.initializeShopTabs()

	storeGui.Enabled = true

	-- Ensure BuyOrSell menu is visible (in case other menus were previously shown)
	local buyOrSellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.BUY_OR_SELL)
	local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
	local shopFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)

	if buyOrSellFrame then
		buyOrSellFrame.Visible = true
	end
	if sellFrame then
		sellFrame.Visible = false
	end
	if shopFrame then
		shopFrame.Visible = false
	end

	-- Freeze the player
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			originalWalkSpeed = humanoid.WalkSpeed
			humanoid.WalkSpeed = 0
		end
	end
end)
