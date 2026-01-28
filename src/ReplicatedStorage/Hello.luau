-- Remote events for client-server communication
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvent for store activation
local OpenStoreEvent = Instance.new("RemoteEvent")
OpenStoreEvent.Name = "OpenStoreEvent"
OpenStoreEvent.Parent = ReplicatedStorage

return {
	OpenStoreEvent = OpenStoreEvent,
}
