-- Store system for handling store interactions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Ensure the module is loaded first (creates the event)
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Hello"))
-- Then get the event directly from ReplicatedStorage (same instance)
local openStoreEvent = ReplicatedStorage:WaitForChild("OpenStoreEvent")

-- Function to handle cashier trigger touching
local function onCashierTriggerTouched(_triggerPart, hit)
	-- Check if the hit part is part of a player's character
	local character = hit:FindFirstAncestorOfClass("Model")
	if character then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			-- Fire the remote event to open the store on the client
			openStoreEvent:FireClient(player)
		end
	end
end

-- Initialize store system
local function init()
	-- Setup cashier trigger
	local cashierTrigger = workspace:WaitForChild("Store"):WaitForChild("CashierTrigger")
	cashierTrigger.Touched:Connect(function(hit)
		onCashierTriggerTouched(cashierTrigger, hit)
	end)
end

return {
	init = init,
}
