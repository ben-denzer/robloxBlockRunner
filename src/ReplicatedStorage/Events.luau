-- Remote events for client-server communication
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

-- Create RemoteEvent for store activation
local OpenStoreEvent = Instance.new("RemoteEvent")
OpenStoreEvent.Name = Constants.EVENTS.OPEN_STORE
OpenStoreEvent.Parent = ReplicatedStorage

-- Create RemoteEvent for store closing
local CloseStoreEvent = Instance.new("RemoteEvent")
CloseStoreEvent.Name = Constants.EVENTS.CLOSE_STORE
CloseStoreEvent.Parent = ReplicatedStorage

-- Create RemoteFunction for selling blocks
local SellBlocksEvent = Instance.new("RemoteFunction")
SellBlocksEvent.Name = Constants.EVENTS.SELL_BLOCKS
SellBlocksEvent.Parent = ReplicatedStorage

-- Create RemoteFunction for buying cart items
local BuyCartEvent = Instance.new("RemoteFunction")
BuyCartEvent.Name = Constants.EVENTS.BUY_CART
BuyCartEvent.Parent = ReplicatedStorage

return {
	OpenStoreEvent = OpenStoreEvent,
	CloseStoreEvent = CloseStoreEvent,
	SellBlocksEvent = SellBlocksEvent,
	BuyCartEvent = BuyCartEvent,
}
