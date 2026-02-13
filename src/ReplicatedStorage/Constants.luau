-- Game constants
-- This file contains shared constants used across the game

local SHOP_ITEMS = {
	CART_60 = "Cart60",
	CART_200 = "Cart200",
	CART_600 = "Cart600",
	GRAVITY_COIL = "GravityCoil",
	SUPER_GRAVITY_COIL = "SuperGravityCoil",
}

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
			BUY_TOOLS = "BuyToolsFrame",
			BUY_PETS = "BuyPetsFrame",
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
			TOOLS_TAB = "ToolsTab",
			PETS_TAB = "PetsTab",
			START = "Start Button",
			SHOP_ITEMS = SHOP_ITEMS,
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
			BUY_GRAVITY_COIL_BUTTON = "buy-gravity-coil-button",
		},
		STORAGE = {
			TAB_STORAGE = "TabStorage",
		},
		ASSETS = {
			OWNED_ITEM_IMAGE = "rbxassetid://115063685134455",
		},
	},

	-- Tools available for purchase
	TOOLS = {
		-- Cart items available for purchase
		-- Each cart sets wagon capacity directly and costs cash
		CART_ITEMS = {
			[SHOP_ITEMS.CART_60] = {
				-- price = 100000,
				price = 5000,
				wagonSize = 60,
				displayName = "Small Cart",
				description = "Holds up to 60 blocks",
				image = "rbxassetid://128450464031364",
				prerequisites = {}, -- No prerequisites for the first cart
			},
			[SHOP_ITEMS.CART_200] = {
				price = 500000,
				wagonSize = 200,
				displayName = "Large Cart",
				description = "Holds up to 200 blocks",
				image = "rbxassetid://117181843097820",
				prerequisites = { SHOP_ITEMS.CART_60 }, -- Requires small cart
			},
			[SHOP_ITEMS.CART_600] = {
				price = 2000000,
				wagonSize = 600,
				displayName = "Huge Cart",
				description = "Holds up to 600 blocks",
				image = "rbxassetid://107001388860949",
				prerequisites = { SHOP_ITEMS.CART_200 }, -- Requires large cart
			},
		},

		-- Gravity coils available for purchase
		-- Each gravity coil provides jump power enhancement and costs cash
		GRAVITY_COILS = {
			[SHOP_ITEMS.GRAVITY_COIL] = {
				price = 4000000,
				jumpPower = 50,
				displayName = "Gravity Coil",
				description = "Jump to save bricks while running",
				image = "rbxassetid://102629918562918",
				prerequisites = {}, -- No prerequisites for the first coil
			},
			[SHOP_ITEMS.SUPER_GRAVITY_COIL] = {
				price = 10000000,
				jumpPower = 90,
				displayName = "Super Gravity Coil",
				description = "4x jump power over normal gravity coils",
				image = "rbxassetid://140234918622988",
				prerequisites = { SHOP_ITEMS.GRAVITY_COIL }, -- Requires regular gravity coil
			},
		},
	},

	-- Block selling transactions
	-- Each transaction sets blocks required and cash reward
	SELL_BLOCKS_TRANSACTIONS = {
		-- ["Sell10BlocksButton"] = { blocks = 10, cash = 10000 },
		["Sell10BlocksButton"] = { blocks = 10, cash = 1000000 },
		["Sell50BlocksButton"] = { blocks = 50, cash = 75000 },
		["Sell100BlocksButton"] = { blocks = 100, cash = 200000 },
		-- Add more transactions as needed - ensure button names in UI match these keys
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
		JUMP_POWER = "JumpPower",
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

	-- Store system configuration
	STORE_SYSTEM = {
		-- Tags
		TAGS = {
			STORE = "store",
			CASHIER_TRIGGER = "cashier-trigger",
		},
	},
}
