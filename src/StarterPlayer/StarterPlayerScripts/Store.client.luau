-- Store GUI functionality
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Store the original walk speed when the store opens
local originalWalkSpeed = 16 -- Default Roblox walk speed

-- Track if buttons have been connected
local buttonsConnected = false

print("Store script loaded")

-- Ensure the module is loaded first (creates the event)
require(ReplicatedStorage:WaitForChild("Hello"))
-- Then get the event directly from ReplicatedStorage (same instance as server)
local openStoreEvent = ReplicatedStorage:WaitForChild("OpenStoreEvent")
local closeStoreEvent = ReplicatedStorage:WaitForChild("CloseStoreEvent")

-- Handle CloseButton click to disable StoreGui
local function onCloseButtonClicked()
	print("Close button clicked")
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
				print("Close button connected")
			else
				print("Close button not found")
			end

			-- Connect SellButton and ShopButton click events
			local sellButton = buyOrSellMenu:FindFirstChild("SellButton")
			local shopButton = buyOrSellMenu:FindFirstChild("ShopButton")

			if sellButton then
				sellButton.MouseButton1Click:Connect(showSellFrame)
				print("Sell button connected")
			end

			if shopButton then
				shopButton.MouseButton1Click:Connect(showShopFrame)
				print("Shop button connected")
			end
		end

		-- Connect BackButton in Sell frame
		local sellFrame = storeGui:FindFirstChild("Sell")
		if sellFrame then
			local backButton = sellFrame:FindFirstChild("BackButton")
			if backButton then
				backButton.MouseButton1Click:Connect(showBuyOrSellFrame)
				print("Sell back button connected")
			end
		end

		-- Connect BackButton in Shop frame
		local shopFrame = storeGui:FindFirstChild("Shop")
		if shopFrame then
			local backButton = shopFrame:FindFirstChild("BackButton")
			if backButton then
				backButton.MouseButton1Click:Connect(showBuyOrSellFrame)
				print("Shop back button connected")
			end
		end

		buttonsConnected = true
	end

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
