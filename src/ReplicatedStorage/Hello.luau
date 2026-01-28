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

return {
	OpenStoreEvent = OpenStoreEvent,
	CloseStoreEvent = CloseStoreEvent,
}
