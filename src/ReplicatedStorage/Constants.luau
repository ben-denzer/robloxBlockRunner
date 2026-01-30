-- Game constants
-- This file contains shared constants used across the game

return {
	-- Player defaults
	DEFAULT_WAGON_SIZE = 20,

	-- Cart items available for purchase
	-- Each cart sets wagon capacity directly and costs cash
	CART_ITEMS = {
		["BuyCart60Button"] = {
			-- price = 100000,
			price = 5000,
			wagonSize = 60,
			displayName = "Small Cart",
			description = "Holds up to 60 blocks",
			image = "rbxassetid://124616601484600",
		},
		["BuyCart200Button"] = {
			price = 500000,
			wagonSize = 200,
			displayName = "Large Cart",
			description = "Holds up to 200 blocks",
			image = "rbxassetid://134561262294236",
		},
		["BuyCart600Button"] = {
			price = 2000000,
			wagonSize = 600,
			displayName = "Huge Cart",
			description = "Holds up to 600 blocks",
			image = "rbxassetid://134561262294236",
		},
	},
}
