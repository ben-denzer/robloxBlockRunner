-- Game constants
-- This file contains shared constants used across the game

return {
	-- Player defaults
	DEFAULT_WAGON_SIZE = 20,

	-- Cart items available for purchase
	-- Each cart sets wagon capacity directly and costs cash
	CART_ITEMS = {
		["Cart60"] = {
			price = 10000,
			wagonSize = 60,
			displayName = "Small Cart",
			description = "Sets wagon capacity to 60 blocks"
		},
		["Cart200"] = {
			price = 50000,
			wagonSize = 200,
			displayName = "Medium Cart",
			description = "Sets wagon capacity to 200 blocks"
		},
		["Cart600"] = {
			price = 200000,
			wagonSize = 600,
			displayName = "Large Cart",
			description = "Sets wagon capacity to 600 blocks"
		}
	}
}
