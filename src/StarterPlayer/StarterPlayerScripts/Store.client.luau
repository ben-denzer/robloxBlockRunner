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

-- Track if buttons have been connected
local buttonsConnected = false

-- Tab state management
local TAB_BLOCKS = "blocks"
local TAB_INVENTORY = "inventory"
local currentSellTab = TAB_BLOCKS -- Default to blocks tab
local sellTabsInitialized = false

-- Colors for tab buttons
local SELECTED_COLOR = Color3.fromRGB(200, 200, 200)
local UNSELECTED_COLOR = Color3.fromRGB(240, 240, 240)

-- Transparency values for disabled buttons
local DISABLED_TRANSPARENCY = 0.7
local ENABLED_TRANSPARENCY = 0

-- Ensure the module is loaded first (creates the event)
require(ReplicatedStorage:WaitForChild("Events"))
-- Then get the event directly from ReplicatedStorage (same instance as server)
local openStoreEvent = ReplicatedStorage:WaitForChild("OpenStoreEvent")
local closeStoreEvent = ReplicatedStorage:WaitForChild("CloseStoreEvent")
local sellBlocksEvent = ReplicatedStorage:WaitForChild("SellBlocksEvent")
local buyCartEvent = ReplicatedStorage:WaitForChild("BuyCartEvent")

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

-- Function to save the current tab selection
local function saveTabSelection(tab)
	currentSellTab = tab
	-- Save to a client-side storage (we'll use a simple approach with a hidden GUI element)
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		-- Create or update a hidden StringValue to store the tab selection
		local tabStorage = storeGui:FindFirstChild("TabStorage")
		if not tabStorage then
			tabStorage = Instance.new("StringValue")
			tabStorage.Name = "TabStorage"
			tabStorage.Parent = storeGui
		end
		tabStorage.Value = tab
	end
end

-- Function to load the saved tab selection
local function loadTabSelection()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		local tabStorage = storeGui:FindFirstChild("TabStorage")
		if tabStorage then
			return tabStorage.Value
		end
	end
	return TAB_BLOCKS -- Default to blocks if no saved selection
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

	-- Find all buttons tagged "sell-blocks-button"
	local sellButtons = {}
	for _, child in ipairs(sellBlocksFrame:GetChildren()) do
		if child:IsA("ImageButton") and child:HasTag("sell-blocks-button") then
			table.insert(sellButtons, child)
		end
	end

	-- Update each button's state
	for _, button in ipairs(sellButtons) do
		local blocksToTurnInValue = button:FindFirstChild("BlocksToTurnIn")
		if blocksToTurnInValue and blocksToTurnInValue:IsA("NumberValue") then
			local blocksRequired = blocksToTurnInValue.Value
			local hasEnoughBlocks = playerBlockCount >= blocksRequired

			-- Update visual state
			local imageLabel = button:FindFirstChild("ImageLabel")
			local blocksText = button:FindFirstChild("BlocksText")
			local cashText = button:FindFirstChild("CashText")

			local transparency = hasEnoughBlocks and ENABLED_TRANSPARENCY or DISABLED_TRANSPARENCY

			if imageLabel then
				imageLabel.ImageTransparency = transparency
			end
			if blocksText then
				blocksText.TextTransparency = transparency
			end
			if cashText then
				cashText.TextTransparency = transparency
			end

			-- Store the enabled state for click handling
			button:SetAttribute("Enabled", hasEnoughBlocks)
		end
	end
end

local function createModalBackdrop()
	local modalBackdrop = Instance.new("TextButton")
	modalBackdrop.Name = "ModalBackdrop"
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

	local errorFrame = storeGui:FindFirstChild("Error")
	if not errorFrame then
		return
	end

	local dynamicText = errorFrame:FindFirstChild("DynamicText")
	if dynamicText then
		dynamicText.Text = errorMessage
	end

	-- Create or show modal backdrop to block all interaction
	local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
	local shopFrame = storeGui:FindFirstChild("Shop")

	if not sellFrame or not shopFrame then
		return
	end

	local visibleFrame = sellFrame.Visible and sellFrame or shopFrame

	if visibleFrame then
		local modalBackdrop = visibleFrame:FindFirstChild("ModalBackdrop")
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

	local errorFrame = storeGui:FindFirstChild("Error")
	if errorFrame then
		errorFrame.Visible = false

		-- Hide modal backdrop to restore interaction
		local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		local shopFrame = storeGui:FindFirstChild("Shop")

		if sellFrame then
			local modalBackdrop = sellFrame:FindFirstChild("ModalBackdrop")
			if modalBackdrop then
				modalBackdrop.Visible = false
			end
		end
		if shopFrame then
			local modalBackdrop = shopFrame:FindFirstChild("ModalBackdrop")
			if modalBackdrop then
				modalBackdrop.Visible = false
			end
		end
	end
end

-- Function to update cart button states based on ownership and cash
local function updateCartButtonStates()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if not storeGui then
		return
	end

	local shopFrame = storeGui:FindFirstChild("Shop")
	if not shopFrame then
		return
	end

	local cartFrame = shopFrame:FindFirstChild("BuyCartsFrame")
	if not cartFrame then
		return
	end

	-- Get player's current cash
	local playerCash = player:GetAttribute("Cash") or 0

	-- Get constants for cart items
	local cartItems = Constants.CART_ITEMS

	-- Find all cart buttons
	local cartButtons = {}
	for _, child in ipairs(cartFrame:GetChildren()) do
		if child:IsA("ImageButton") and child:HasTag("buy-cart-button") then
			table.insert(cartButtons, child)
		end
	end

	-- Update each cart button
	for _, button in ipairs(cartButtons) do
		local cartId = button.Name -- Should match Constants.CART_ITEMS keys
		local cartData = cartItems[cartId]

		if cartData then
			local price = cartData.price
			local hasEnoughCash = playerCash >= price
			local canAfford = hasEnoughCash

			-- Update visual state
			local imageLabel = button:FindFirstChild("ImageLabel")
			local nameText = button:FindFirstChild("NameText")
			local priceText = button:FindFirstChild("CashText")
			local descriptionText = button:FindFirstChild("DescriptionText")

			local transparency = canAfford and ENABLED_TRANSPARENCY or DISABLED_TRANSPARENCY

			if imageLabel then
				imageLabel.ImageTransparency = transparency
				imageLabel.Image = cartData.image
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
			button:SetAttribute("Enabled", canAfford)

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

-- Function to handle cart button clicks
local function onCartButtonClicked(button)
	local isEnabled = button:GetAttribute("Enabled")
	if isEnabled then
		-- Send cart ID to server (server will validate the purchase)
		local cartId = button.Name

		-- Call server to perform the purchase
		local success, result = buyCartEvent:InvokeServer(cartId)

		if success then
			-- Purchase successful, update button states
			updateCartButtonStates()
		else
			-- Show error message from server
			showErrorFrame(result or "Purchase failed")
		end
	else
		showErrorFrame("You cannot purchase this cart right now")
	end
end

-- Function to handle sell button clicks
local function onSellBlocksButtonClicked(button)
	local isEnabled = button:GetAttribute("Enabled")
	if isEnabled then
		-- Send button identifier to server (server will validate the transaction details)
		local buttonIdentifier = button.Name

		-- Call server to perform the transaction
		local success, result1, _ = sellBlocksEvent:InvokeServer(buttonIdentifier)

		if success then
			-- Transaction successful, update button states
			updateSellButtonStates()
		else
			-- Show error message from server
			showErrorFrame(result1 or "Transaction failed")
		end
	else
		-- Show error frame for disabled button
		showErrorFrame("You do not have enough blocks to complete this transaction")
	end
end

-- Function to switch to blocks tab
local function switchToBlocksTab()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		if sellFrame then
			local sellBlocksFrame = sellFrame:FindFirstChild(UI_ELEMENTS.FRAMES.SELL_BLOCKS)
			local sellInventoryFrame = sellFrame:FindFirstChild("SellInventoryFrame")
			local tabsFrame = sellFrame:FindFirstChild("Tabs")
			local blocksTab = tabsFrame and tabsFrame:FindFirstChild("BlocksTab")
			local inventoryTab = tabsFrame and tabsFrame:FindFirstChild("InventoryTab")

			-- Show/hide frames
			if sellBlocksFrame then
				sellBlocksFrame.Visible = true
				-- Update button states when frame becomes visible
				updateSellButtonStates()
			end
			if sellInventoryFrame then
				sellInventoryFrame.Visible = false
			end

			-- Update button colors
			if blocksTab then
				blocksTab.BackgroundColor3 = SELECTED_COLOR
			end
			if inventoryTab then
				inventoryTab.BackgroundColor3 = UNSELECTED_COLOR
			end

			saveTabSelection(TAB_BLOCKS)
		end
	end
end

-- Function to switch to inventory tab
local function switchToInventoryTab()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		if sellFrame then
			local sellBlocksFrame = sellFrame:FindFirstChild(UI_ELEMENTS.FRAMES.SELL_BLOCKS)
			local sellInventoryFrame = sellFrame:FindFirstChild("SellInventoryFrame")
			local tabsFrame = sellFrame:FindFirstChild("Tabs")
			local blocksTab = tabsFrame and tabsFrame:FindFirstChild("BlocksTab")
			local inventoryTab = tabsFrame and tabsFrame:FindFirstChild("InventoryTab")

			-- Show/hide frames
			if sellBlocksFrame then
				sellBlocksFrame.Visible = false
			end
			if sellInventoryFrame then
				sellInventoryFrame.Visible = true
			end

			-- Update button colors
			if blocksTab then
				blocksTab.BackgroundColor3 = UNSELECTED_COLOR
			end
			if inventoryTab then
				inventoryTab.BackgroundColor3 = SELECTED_COLOR
			end

			saveTabSelection(TAB_INVENTORY)
		end
	end
end

-- Function to initialize sell tabs
local function initializeSellTabs()
	if sellTabsInitialized then
		return
	end

	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		if sellFrame then
			local tabsFrame = sellFrame:FindFirstChild("Tabs")
			if tabsFrame then
				local blocksTab = tabsFrame:FindFirstChild("BlocksTab")
				local inventoryTab = tabsFrame:FindFirstChild("InventoryTab")

				-- Connect tab button events
				if blocksTab then
					blocksTab.MouseButton1Click:Connect(switchToBlocksTab)
				end
				if inventoryTab then
					inventoryTab.MouseButton1Click:Connect(switchToInventoryTab)
				end
			end
		end
	end

	sellTabsInitialized = true
end

-- Function to show Sell frame and hide others
local function showSellFrame()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		local buyOrSellFrame = storeGui:FindFirstChild("BuyOrSell")
		local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		local shopFrame = storeGui:FindFirstChild("Shop")

		if buyOrSellFrame then
			buyOrSellFrame.Visible = false
		end
		if sellFrame then
			sellFrame.Visible = true
		end
		if shopFrame then
			shopFrame.Visible = false
		end

		-- Initialize tabs if not already done
		initializeSellTabs()

		-- Load saved tab selection and switch to it
		currentSellTab = loadTabSelection()
		if currentSellTab == TAB_BLOCKS then
			switchToBlocksTab()
		elseif currentSellTab == TAB_INVENTORY then
			switchToInventoryTab()
		end
	end
end

-- Function to show Shop frame and hide others
local function showShopFrame()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		local buyOrSellFrame = storeGui:FindFirstChild("BuyOrSell")
		local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		local shopFrame = storeGui:FindFirstChild("Shop")

		if buyOrSellFrame then
			buyOrSellFrame.Visible = false
		end
		if sellFrame then
			sellFrame.Visible = false
		end
		if shopFrame then
			shopFrame.Visible = true
			-- Update cart button states when shop frame becomes visible
			updateCartButtonStates()
		end
	end
end

-- Function to show BuyOrSell frame and hide others
local function showBuyOrSellFrame()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		local buyOrSellFrame = storeGui:FindFirstChild("BuyOrSell")
		local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		local shopFrame = storeGui:FindFirstChild("Shop")

		if buyOrSellFrame then
			buyOrSellFrame.Visible = true
		end
		if sellFrame then
			sellFrame.Visible = false
		end
		if shopFrame then
			shopFrame.Visible = false
		end
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
		local buyOrSellMenu = storeGui:FindFirstChild("BuyOrSell")
		if buyOrSellMenu then
			local closeButton = buyOrSellMenu:FindFirstChild("CloseButton")
			if closeButton then
				closeButton.MouseButton1Click:Connect(onCloseButtonClicked)
			else
				print("Close button not found")
			end

			-- Connect SellButton and ShopButton click events
			local sellButton = buyOrSellMenu:FindFirstChild("SellButton")
			local shopButton = buyOrSellMenu:FindFirstChild("ShopButton")

			if sellButton then
				sellButton.MouseButton1Click:Connect(showSellFrame)
			end

			if shopButton then
				shopButton.MouseButton1Click:Connect(showShopFrame)
			end
		end

		-- Connect BackButton in Sell frame
		local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		if sellFrame then
			local backButton = sellFrame:FindFirstChild("BackButton")
			if backButton then
				backButton.MouseButton1Click:Connect(showBuyOrSellFrame)
			end
		end

		-- Connect BackButton in Shop frame
		local shopFrame = storeGui:FindFirstChild("Shop")
		if shopFrame then
			local backButton = shopFrame:FindFirstChild("BackButton")
			if backButton then
				backButton.MouseButton1Click:Connect(showBuyOrSellFrame)
			end
		end

		-- Connect sell button click events
		local sellFrameLocal = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		if sellFrameLocal then
			local sellBlocksFrame = sellFrameLocal:FindFirstChild(UI_ELEMENTS.FRAMES.SELL_BLOCKS)
			if sellBlocksFrame then
				-- Connect all sell buttons
				for _, child in ipairs(sellBlocksFrame:GetChildren()) do
					if child:IsA("ImageButton") and child:HasTag("sell-blocks-button") then
						child.MouseButton1Click:Connect(function()
							onSellBlocksButtonClicked(child)
						end)
					end
				end
			end
		end

		-- Connect error frame cancel button
		local errorFrame = storeGui:FindFirstChild("Error")
		if errorFrame then
			local cancelButton = errorFrame:FindFirstChild("CancelButton")
			if cancelButton then
				cancelButton.MouseButton1Click:Connect(hideErrorFrame)
			end
		end

		-- Connect cart button click events
		local shopFrameConnect = storeGui:FindFirstChild("Shop")
		if shopFrameConnect then
			local cartFrame = shopFrameConnect:FindFirstChild("BuyCartsFrame")
			if cartFrame then
				-- Connect all cart buttons
				for _, child in ipairs(cartFrame:GetChildren()) do
					if child:IsA("ImageButton") and child:HasTag("buy-cart-button") then
						child.MouseButton1Click:Connect(function()
							onCartButtonClicked(child)
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
			local shopFrameLocal = storeGuiLocal:FindFirstChild("Shop")
			if shopFrameLocal and shopFrameLocal.Visible then
				updateCartButtonStates()
			end
		end
	end)

	-- Initialize sell tabs
	initializeSellTabs()

	storeGui.Enabled = true

	-- Ensure BuyOrSell menu is visible (in case other menus were previously shown)
	local buyOrSellFrame = storeGui:FindFirstChild("BuyOrSell")
	local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
	local shopFrame = storeGui:FindFirstChild("Shop")

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
