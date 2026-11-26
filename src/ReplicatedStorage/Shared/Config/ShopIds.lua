--!strict
-- Config.ShopIds: the Roblox ids of the 10 passes and 9 developer products, by Ids.PASSES / Ids.PRODUCTS key.
-- The real ids from the Creator Dashboard (M2-00, 2026-11-25; source: team/assets.md "Passes and developer
-- products", same keys). 0 would mean stand-in (no MarketplaceService call; checks use TestHooks FakeReceipt).
-- Exposed as Config.Shop.IDS by Config/init. Owned by the main session and M2-01; nobody else edits this file
-- (TEAM CALL M2-01-5). A changed id is changed here and in team/assets.md together.
local ShopIds = {
	-- passes
	pass_auto_punch = 2099520308,
	pass_perfect_auto_punch = 2099490208,
	pass_2x_power = 2100054256,
	pass_2x_cash = 2099214230,
	pass_fast_carry = 2099688287,
	pass_long_lock = 2100348165,
	pass_extra_spots = 2098776390,
	pass_quick_hands = 2101224215,
	pass_iron_grip = 2101823523,
	pass_starter_pack = 2099874270,
	-- developer products
	product_cash_small = 3736423996,
	product_cash_medium = 3736424184,
	product_cash_large = 3736424519,
	product_cash_huge = 3736424302,
	product_spin_1 = 3736424361,
	product_spin_3 = 3736424608,
	product_spin_10 = 3736424705,
	product_instant_shield = 3736424920,
	product_shield_breaker = 3736425030,
}

return ShopIds
