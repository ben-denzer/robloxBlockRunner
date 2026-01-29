-- Store GUI functionality
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Store the original walk speed when the store opens
local originalWalkSpeed = 16 -- Default Roblox walk speed

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

-- Ensure the module is loaded first (creates the event)
require(ReplicatedStorage:WaitForChild("Hello"))
-- Then get the event directly from ReplicatedStorage (same instance as server)
local openStoreEvent = ReplicatedStorage:WaitForChild("OpenStoreEvent")
local closeStoreEvent = ReplicatedStorage:WaitForChild("CloseStoreEvent")

-- Handle CloseButton click to disable StoreGui
local function onCloseButtonClicked()
	local storeGui = playerGui:FindFirstChild("StoreGui")
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
	local storeGui = playerGui:FindFirstChild("StoreGui")
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
	local storeGui = playerGui:FindFirstChild("StoreGui")
	if storeGui then
		local tabStorage = storeGui:FindFirstChild("TabStorage")
		if tabStorage then
			return tabStorage.Value
		end
	end
	return TAB_BLOCKS -- Default to blocks if no saved selection
end

-- Function to switch to blocks tab
local function switchToBlocksTab()
	local storeGui = playerGui:FindFirstChild("StoreGui")
	if storeGui then
		local sellFrame = storeGui:FindFirstChild("Sell")
		if sellFrame then
			local sellBlocksFrame = sellFrame:FindFirstChild("SellBlocksFrame")
			local sellInventoryFrame = sellFrame:FindFirstChild("SellInventoryFrame")
			local tabsFrame = sellFrame:FindFirstChild("Tabs")
			local blocksTab = tabsFrame and tabsFrame:FindFirstChild("BlocksTab")
			local inventoryTab = tabsFrame and tabsFrame:FindFirstChild("InventoryTab")

			-- Show/hide frames
			if sellBlocksFrame then
				sellBlocksFrame.Visible = true
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
	local storeGui = playerGui:FindFirstChild("StoreGui")
	if storeGui then
		local sellFrame = storeGui:FindFirstChild("Sell")
		if sellFrame then
			local sellBlocksFrame = sellFrame:FindFirstChild("SellBlocksFrame")
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

	local storeGui = playerGui:FindFirstChild("StoreGui")
	if storeGui then
		local sellFrame = storeGui:FindFirstChild("Sell")
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
	local storeGui = playerGui:FindFirstChild("StoreGui")
	if storeGui then
		local buyOrSellFrame = storeGui:FindFirstChild("BuyOrSell")
		local sellFrame = storeGui:FindFirstChild("Sell")
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
	local storeGui = playerGui:FindFirstChild("StoreGui")
	if storeGui then
		local buyOrSellFrame = storeGui:FindFirstChild("BuyOrSell")
		local sellFrame = storeGui:FindFirstChild("Sell")
		local shopFrame = storeGui:FindFirstChild("Shop")

		if buyOrSellFrame then
			buyOrSellFrame.Visible = false
		end
		if sellFrame then
			sellFrame.Visible = false
		end
		if shopFrame then
			shopFrame.Visible = true
		end
	end
end

-- Function to show BuyOrSell frame and hide others
local function showBuyOrSellFrame()
	local storeGui = playerGui:FindFirstChild("StoreGui")
	if storeGui then
		local buyOrSellFrame = storeGui:FindFirstChild("BuyOrSell")
		local sellFrame = storeGui:FindFirstChild("Sell")
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
	local storeGui = playerGui:FindFirstChild("StoreGui")
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
		local sellFrame = storeGui:FindFirstChild("Sell")
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

		buttonsConnected = true
	end

	-- Initialize sell tabs
	initializeSellTabs()

	storeGui.Enabled = true

	-- Ensure BuyOrSell menu is visible (in case other menus were previously shown)
	local buyOrSellFrame = storeGui:FindFirstChild("BuyOrSell")
	local sellFrame = storeGui:FindFirstChild("Sell")
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
