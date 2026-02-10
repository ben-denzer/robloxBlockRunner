-- Store UI Manager Module
-- Handles frame showing/hiding and tab management logic

local StoreUIManager = {}

-- Dependencies to be set during initialization
local playerGui = nil
local UI_ELEMENTS = nil
local TAB_BLOCKS = "blocks"
local TAB_INVENTORY = "inventory"
local TAB_TOOLS = "tools"
local TAB_PETS = "pets"
local currentSellTab = TAB_BLOCKS
local currentShopTab = TAB_TOOLS
local sellTabsInitialized = false
local shopTabsInitialized = false

-- Colors for tab buttons
local SELECTED_COLOR = Color3.fromRGB(200, 200, 200)
local UNSELECTED_COLOR = Color3.fromRGB(240, 240, 240)

-- Function to save the current tab selection
local function saveTabSelection(tab, tabType)
	if tabType == "sell" then
		currentSellTab = tab
	elseif tabType == "shop" then
		currentShopTab = tab
	end

	-- Save to a client-side storage (we'll use a simple approach with a hidden GUI element)
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		-- Create or update a hidden StringValue to store the tab selection
		local tabStorage = storeGui:FindFirstChild(UI_ELEMENTS.STORAGE.TAB_STORAGE)
		if not tabStorage then
			tabStorage = Instance.new("StringValue")
			tabStorage.Name = UI_ELEMENTS.STORAGE.TAB_STORAGE
			tabStorage.Parent = storeGui
		end

		-- Store both sell and shop tabs as JSON
		local tabData = {
			sell = currentSellTab,
			shop = currentShopTab,
		}
		local success, jsonData = pcall(function()
			return game:GetService("HttpService"):JSONEncode(tabData)
		end)
		if success then
			tabStorage.Value = jsonData
		end
	end
end

-- Function to load the saved tab selection
local function loadTabSelection(tabType)
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		local tabStorage = storeGui:FindFirstChild(UI_ELEMENTS.STORAGE.TAB_STORAGE)
		if tabStorage and tabStorage.Value ~= "" then
			local success, tabData = pcall(function()
				return game:GetService("HttpService"):JSONDecode(tabStorage.Value)
			end)
			if success and tabData[tabType] then
				return tabData[tabType]
			end
		end
	end

	-- Return defaults
	if tabType == "sell" then
		return TAB_BLOCKS
	elseif tabType == "shop" then
		return TAB_TOOLS
	end

	return TAB_BLOCKS -- Fallback default
end

-- Function to switch to blocks tab
local function switchToBlocksTab(updateSellButtonStatesCallback)
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		if sellFrame then
			local sellBlocksFrame = sellFrame:FindFirstChild(UI_ELEMENTS.FRAMES.SELL_BLOCKS)
			local sellInventoryFrame = sellFrame:FindFirstChild(UI_ELEMENTS.FRAMES.SELL_INVENTORY)
			local tabsFrame = sellFrame:FindFirstChild(UI_ELEMENTS.FRAMES.TABS)
			local blocksTab = tabsFrame and tabsFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.BLOCKS_TAB)
			local inventoryTab = tabsFrame and tabsFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.INVENTORY_TAB)

			-- Show/hide frames
			if sellBlocksFrame then
				sellBlocksFrame.Visible = true
				-- Update button states when frame becomes visible
				if updateSellButtonStatesCallback then
					updateSellButtonStatesCallback()
				end
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

			saveTabSelection(TAB_BLOCKS, "sell")
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
			local sellInventoryFrame = sellFrame:FindFirstChild(UI_ELEMENTS.FRAMES.SELL_INVENTORY)
			local tabsFrame = sellFrame:FindFirstChild(UI_ELEMENTS.FRAMES.TABS)
			local blocksTab = tabsFrame and tabsFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.BLOCKS_TAB)
			local inventoryTab = tabsFrame and tabsFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.INVENTORY_TAB)

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

			saveTabSelection(TAB_INVENTORY, "sell")
		end
	end
end

-- Function to initialize sell tabs
local function initializeSellTabs(updateSellButtonStatesCallback)
	if sellTabsInitialized then
		return
	end

	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		if sellFrame then
			local tabsFrame = sellFrame:FindFirstChild(UI_ELEMENTS.FRAMES.TABS)
			if tabsFrame then
				local blocksTab = tabsFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.BLOCKS_TAB)
				local inventoryTab = tabsFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.INVENTORY_TAB)

				-- Connect tab button events
				if blocksTab then
					blocksTab.MouseButton1Click:Connect(function()
						switchToBlocksTab(updateSellButtonStatesCallback)
					end)
				end
				if inventoryTab then
					inventoryTab.MouseButton1Click:Connect(switchToInventoryTab)
				end
			end
		end
	end

	sellTabsInitialized = true
end

-- Function to switch to tools tab
local function switchToToolsTab()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		local shopFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)
		if shopFrame then
			local buyToolsFrame = shopFrame:FindFirstChild(UI_ELEMENTS.FRAMES.BUY_TOOLS)
			local buyPetsFrame = shopFrame:FindFirstChild(UI_ELEMENTS.FRAMES.BUY_PETS)
			local tabsFrame = shopFrame:FindFirstChild(UI_ELEMENTS.FRAMES.TABS)
			local toolsTab = tabsFrame and tabsFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.TOOLS_TAB)
			local petsTab = tabsFrame and tabsFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.PETS_TAB)

			-- Show/hide frames
			if buyToolsFrame then
				buyToolsFrame.Visible = true
			end
			if buyPetsFrame then
				buyPetsFrame.Visible = false
			end

			-- Update button colors
			if toolsTab then
				toolsTab.BackgroundColor3 = SELECTED_COLOR
			end
			if petsTab then
				petsTab.BackgroundColor3 = UNSELECTED_COLOR
			end

			saveTabSelection(TAB_TOOLS, "shop")
		end
	end
end

-- Function to switch to pets tab
local function switchToPetsTab()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		local shopFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)
		if shopFrame then
			local buyToolsFrame = shopFrame:FindFirstChild(UI_ELEMENTS.FRAMES.BUY_TOOLS)
			local buyPetsFrame = shopFrame:FindFirstChild(UI_ELEMENTS.FRAMES.BUY_PETS)
			local tabsFrame = shopFrame:FindFirstChild(UI_ELEMENTS.FRAMES.TABS)
			local toolsTab = tabsFrame and tabsFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.TOOLS_TAB)
			local petsTab = tabsFrame and tabsFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.PETS_TAB)

			-- Show/hide frames
			if buyToolsFrame then
				buyToolsFrame.Visible = false
			end
			if buyPetsFrame then
				buyPetsFrame.Visible = true
			end

			-- Update button colors
			if toolsTab then
				toolsTab.BackgroundColor3 = UNSELECTED_COLOR
			end
			if petsTab then
				petsTab.BackgroundColor3 = SELECTED_COLOR
			end

			saveTabSelection(TAB_PETS, "shop")
		end
	end
end

-- Function to initialize shop tabs
local function initializeShopTabs()
	if shopTabsInitialized then
		return
	end

	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		local shopFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)
		if shopFrame then
			local tabsFrame = shopFrame:FindFirstChild(UI_ELEMENTS.FRAMES.TABS)
			if tabsFrame then
				local toolsTab = tabsFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.TOOLS_TAB)
				local petsTab = tabsFrame:FindFirstChild(UI_ELEMENTS.BUTTONS.PETS_TAB)

				-- Connect tab button events
				if toolsTab then
					toolsTab.MouseButton1Click:Connect(switchToToolsTab)
				end
				if petsTab then
					petsTab.MouseButton1Click:Connect(switchToPetsTab)
				end
			end
		end
	end

	shopTabsInitialized = true
end

-- Function to show Sell frame and hide others
local function showSellFrame(updateSellButtonStates)
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		local buyOrSellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.BUY_OR_SELL)
		local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		local shopFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)

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
		initializeSellTabs(updateSellButtonStates)

		-- Load saved tab selection and switch to it
		currentSellTab = loadTabSelection("sell")
		if currentSellTab == TAB_BLOCKS then
			switchToBlocksTab(updateSellButtonStates)
		elseif currentSellTab == TAB_INVENTORY then
			switchToInventoryTab()
		end
	end
end

-- Function to show Shop frame and hide others
local function showShopFrame(updateCartButtonStates)
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
		local buyOrSellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.BUY_OR_SELL)
		local sellFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SELL)
		local shopFrame = storeGui:FindFirstChild(UI_ELEMENTS.FRAMES.SHOP)

		if buyOrSellFrame then
			buyOrSellFrame.Visible = false
		end
		if sellFrame then
			sellFrame.Visible = false
		end
		if shopFrame then
			shopFrame.Visible = true

			-- Initialize tabs if not already done
			initializeShopTabs()

			-- Load saved tab selection and switch to it
			currentShopTab = loadTabSelection("shop")
			if currentShopTab == TAB_PETS then
				switchToPetsTab()
			else
				-- Default to tools if invalid or tools tab
				switchToToolsTab()
			end

			-- Update cart button states when shop frame becomes visible
			if updateCartButtonStates then
				updateCartButtonStates()
			end
		end
	end
end

-- Function to show BuyOrSell frame and hide others
local function showBuyOrSellFrame()
	local storeGui = playerGui:FindFirstChild(UI_ELEMENTS.GUI.STORE)
	if storeGui then
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
	end
end

-- Initialize the module with required dependencies
function StoreUIManager.init(dependencies)
	playerGui = dependencies.playerGui
	UI_ELEMENTS = dependencies.UI_ELEMENTS
end

-- Public API
StoreUIManager.showSellFrame = showSellFrame
StoreUIManager.showShopFrame = showShopFrame
StoreUIManager.showBuyOrSellFrame = showBuyOrSellFrame
StoreUIManager.initializeSellTabs = initializeSellTabs
StoreUIManager.initializeShopTabs = initializeShopTabs

return StoreUIManager
