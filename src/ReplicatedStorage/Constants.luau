-- Game constants
-- This file contains shared constants used across the game

return {
	-- Player defaults
	DEFAULT_WAGON_SIZE = 20,

	UI_ELEMENTS = {
		GUI = {
			STORE = "StoreGui",
			SCOREBOARD = "ScoreboardGui",
			START_MENU = "StartMenuGui",
		},
		FRAMES = {
			BUY_OR_SELL = "BuyOrSell",
			CONFIRMATION = "Confirmation",
			ERROR = "Error",
			SELL = "Sell",
			SHOP = "Shop",
			TABS = "Tabs",
			SELL_BLOCKS = "SellBlocksFrame",
			SELL_INVENTORY = "SellInventoryFrame",
			BUY_CARTS = "BuyCartsFrame",
			SCOREBOARD = "Scoreboard",
			START_MENU = "StartMenu",
		},
		BUTTONS = {
			CLOSE = "CloseButton",
			BACK = "BackButton",
			CANCEL = "CancelButton",
			CONFIRM = "ConfirmButton",
			SELL = "SellButton",
			SHOP = "ShopButton",
			BLOCKS_TAB = "BlocksTab",
			INVENTORY_TAB = "InventoryTab",
			START = "Start Button",
		},
		ELEMENTS = {
			IMAGE_LABEL = "ImageLabel",
			BLOCKS_TEXT = "BlocksText",
			CASH_TEXT = "CashText",
			NAME_TEXT = "NameText",
			DESCRIPTION_TEXT = "DescriptionText",
			DYNAMIC_TEXT = "DynamicText",
			MODAL_BACKDROP = "ModalBackdrop",
			BLOCK_COUNT = "BlockCount",
			CASH_COUNT = "CashCount",
		},
		ATTRIBUTES = {
			BLOCKS_TO_TURN_IN = "BlocksToTurnIn",
			PAYOUT = "Payout",
			ENABLED = "Enabled",
		},
		TAGS = {
			SELL_BLOCKS_BUTTON = "sell-blocks-button",
			BUY_CART_BUTTON = "buy-cart-button",
		},
		STORAGE = {
			TAB_STORAGE = "TabStorage",
		},
		ASSETS = {
			OWNED_ITEM_IMAGE = "rbxassetid://115063685134455",
		},
	},

	-- Cart items available for purchase
	-- Each cart sets wagon capacity directly and costs cash
	CART_ITEMS = {
		["BuyCart60Button"] = {
			-- price = 100000,
			price = 5000,
			wagonSize = 60,
			displayName = "Small Cart",
			description = "Holds up to 60 blocks",
			image = "rbxassetid://128450464031364",
		},
		["BuyCart200Button"] = {
			price = 500000,
			wagonSize = 200,
			displayName = "Large Cart",
			description = "Holds up to 200 blocks",
			image = "rbxassetid://117181843097820",
		},
		["BuyCart600Button"] = {
			price = 2000000,
			wagonSize = 600,
			displayName = "Huge Cart",
			description = "Holds up to 600 blocks",
			image = "rbxassetid://107001388860949",
		},
	},

	-- World objects and locations
	WORLD_OBJECTS = {
		STORE = "Store",
		CASHIER_TRIGGER = "CashierTrigger",
		TRACK_1 = "Track1",
		TRACK_1_SPAWN = "Track1Spawn",
	},

	-- Remote events
	EVENTS = {
		OPEN_STORE = "OpenStoreEvent",
		CLOSE_STORE = "CloseStoreEvent",
		SELL_BLOCKS = "SellBlocksEvent",
		BUY_CART = "BuyCartEvent",
	},

	-- Player data attributes
	PLAYER_ATTRIBUTES = {
		BLOCK_COUNT = "BlockCount",
		CASH = "Cash",
		WAGON_SIZE = "WagonSize",
	},

	-- Transaction identifiers (must match button names in UI)
	TRANSACTIONS = {
		SELL_10_BLOCKS = "Sell10BlocksButton",
		SELL_50_BLOCKS = "Sell50BlocksButton",
		SELL_100_BLOCKS = "Sell100BlocksButton",
	},

	-- Block system configuration
	BLOCK_SYSTEM = {
		-- Distance thresholds
		PLAYER_NEAR_RADIUS = 5, -- Radius to check for players near respawn positions (studs)

		-- Tags
		TAGS = {
			STEPPING_STONE = "stepping-stone",
			TRACK = "track",
			BLOCK = "block",
			NO_RESPAWN = "no-respawn",
			FAKE_FLOOR = "fake-floor",
		},
	},

	-- Cash system configuration
	CASH_SYSTEM = {
		-- Default values
		DEFAULT_CASH_COUNT = 100, -- Default cash amount per cash part

		-- Distance thresholds
		PLAYER_NEAR_RADIUS = 5, -- Radius to check for players near respawn positions (studs)

		-- Tags
		TAGS = {
			CASH = "cash",
			NO_RESPAWN = "no-respawn",
		},
	},
}
