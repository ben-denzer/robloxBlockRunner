-- Remote events for client-server communication
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvent for store activation
local OpenStoreEvent = Instance.new("RemoteEvent")
OpenStoreEvent.Name = "OpenStoreEvent"
OpenStoreEvent.Parent = ReplicatedStorage

-- Create RemoteEvent for store closing
local CloseStoreEvent = Instance.new("RemoteEvent")
CloseStoreEvent.Name = "CloseStoreEvent"
CloseStoreEvent.Parent = ReplicatedStorage

-- Create RemoteFunction for selling blocks
local SellBlocksEvent = Instance.new("RemoteFunction")
SellBlocksEvent.Name = "SellBlocksEvent"
SellBlocksEvent.Parent = ReplicatedStorage

-- Create RemoteFunction for buying cart items
local BuyCartEvent = Instance.new("RemoteFunction")
BuyCartEvent.Name = "BuyCartEvent"
BuyCartEvent.Parent = ReplicatedStorage

return {
	OpenStoreEvent = OpenStoreEvent,
	CloseStoreEvent = CloseStoreEvent,
	SellBlocksEvent = SellBlocksEvent,
	BuyCartEvent = BuyCartEvent,
}
