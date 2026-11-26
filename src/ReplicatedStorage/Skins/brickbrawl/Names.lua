--!strict
-- brickbrawl / Names: display names by id: game, zones (1..6), creatures (z<zone>_t<tier>), hazards, bag tiers, product keys. Source: brief.md, 'Content for version 1'
-- Filled at M1-02 (gui-designer) from the brief (Content for version 1, creatures table, shop tables) and the style guide.
-- All 36 creatures and the whole shop are listed now so later tasks add nothing. Names are in the brief's own case;
-- the views upper-case where the style guide says caps (tier chips, band word). grades and hudWords are stored as drawn (caps).
return {
	game = "Huss for Bosses",

	zones = { "Brick Meadow", "Sand Blocks", "Pirate Plates", "Ice Blocks", "Lava Bricks", "Space Baseplate" },

	tiers = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" },

	creatures = {
		z1_t1 = "Chomp Frog", z1_t2 = "Bop Bunny", z1_t3 = "Bumble Brute", z1_t4 = "Headbutt Ram", z1_t5 = "Timber Bear", z1_t6 = "Bloom Stag",
		z2_t1 = "Roll Beetle", z2_t2 = "Snap Scorpion", z2_t3 = "Prickle Gecko", z2_t4 = "Thump Camel", z2_t5 = "Dune Cobra", z2_t6 = "Sun Sphinx",
		z3_t1 = "Pinch Crab", z3_t2 = "Plunder Parrot", z3_t3 = "Bit Shark", z3_t4 = "Tangle Squid", z3_t5 = "Cannon Turtle", z3_t6 = "Tidal Kraken",
		z4_t1 = "Waddle Penguin", z4_t2 = "Tusk Walrus", z4_t3 = "Flurry Fox", z4_t4 = "Frost Byte", z4_t5 = "Glacier Mammoth", z4_t6 = "Aurora Owl",
		z5_t1 = "Cinder Newt", z5_t2 = "Ash Bat", z5_t3 = "Coal Boar", z5_t4 = "Molten Gorilla", z5_t5 = "Ember Drake", z5_t6 = "Magma Hydra",
		z6_t1 = "Moon Mite", z6_t2 = "Orbit Jelly", z6_t3 = "Comet Hound", z6_t4 = "Nebula Ray", z6_t5 = "Void Mantis", z6_t6 = "Star Golem",
	},

	hazards = { "Rolling Log", "Tumble Cactus", "Swinging Anchor", "Sliding Ice Block", "Lava Burst Row", "Orbit Meteor" },

	bags = { "Starter Bag", "Sand Bag", "Plank Bag", "Ice Bag", "Lava Bag", "Star Bag" },

	-- Fight difficulty words (brief, system 4), in the order of Tokens.colors.band
	bands = {
		easy = "Easy",
		fair = "Fair",
		hard = "Hard",
		veryHard = "Very hard",
		brutal = "Brutal",
		impossible = "Near impossible",
	},

	grades = { good = "GOOD", perfect = "PERFECT" },

	-- The words the HUD and prompts print (style guide 6: caps on buttons and labels)
	hudWords = { huss = "HUSS!", run = "RUN", place = "PLACE", grab = "GRAB", power = "POWER", cash = "CASH" },

	-- Shop products by Ids.PASSES / Ids.PRODUCTS key (brief, system 13). M2 uses them; declared now so nothing is added later.
	products = {
		pass_auto_punch = "Auto Punch",
		pass_perfect_auto_punch = "Perfect Auto Punch",
		pass_2x_power = "2x Power",
		pass_2x_cash = "2x Cash",
		pass_fast_carry = "Fast Carry",
		pass_long_lock = "Long Lock",
		pass_extra_spots = "Extra Spots",
		pass_quick_hands = "Quick Hands",
		pass_iron_grip = "Iron Grip",
		pass_starter_pack = "Starter Pack",
		product_cash_small = "Small Cash Pack",
		product_cash_medium = "Medium Cash Pack",
		product_cash_large = "Large Cash Pack",
		product_cash_huge = "Huge Cash Pack",
		product_spin_1 = "Lucky Boss Spin x1",
		product_spin_3 = "Lucky Boss Spin x3",
		product_spin_10 = "Lucky Boss Spin x10",
		product_instant_shield = "Instant Shield",
		product_shield_breaker = "Shield Breaker",
	},
}
