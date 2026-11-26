--!strict
-- Config.Shop: the shop (brief system 13; m2-contract.md C "Shop", "Receipt rules"). Owned by M2-18 (never IDS: the
-- Roblox ids are Config/ShopIds, exposed as Config.Shop.IDS by Config/init). No prices: they are set in the dashboard.
-- Tests override at runtime; never edit this file for a test.
local Shop = {}

-- Cash packs: `seconds` of the player's current total boss income (placed bosses, with the rebirth and 2x Cash
-- multipliers), at least `min`. Bought cash (addCash(.., true)).
Shop.PACKS = {
	product_cash_small = { seconds = 15 * 60, min = 2500 },
	product_cash_medium = { seconds = 60 * 60, min = 10000 },
	product_cash_large = { seconds = 4 * 60 * 60, min = 40000 },
	product_cash_huge = { seconds = 12 * 60 * 60, min = 120000 },
}
-- A quote (the amount on the button) is good for this long; after that Buy answers 'stale' with new quotes.
Shop.QUOTE_S = 300
-- An amount held when the server prompted a cash pack stays good this long for its receipt (the dialog may sit open).
Shop.HELD_S = 600

-- Spin tickets per spin product.
Shop.SPIN_TICKETS = { product_spin_1 = 1, product_spin_3 = 3, product_spin_10 = 10 }

-- Starter Pack contents (fixed for every player): bought cash and the zone 1 Epic (z1_t4) to the crate.
Shop.STARTER_CASH = 5000
Shop.STARTER_CREATURE = "z1_t4"
-- The contents are recorded under "<this>:<the Ram's uid>" (one id per attempt; starterPackGiven is the once-guard).
Shop.STARTER_RECORD_ID = "starter_pack"
-- A grant that could not be written (temp profile, failed write) is tried again this often while the player stays.
Shop.STARTER_RETRY_S = 30
-- TEAM CALL M2-18-3: in Studio, Roblox's real answer (the test account owns every pass) never grants the contents;
-- only the PassOwned hook does, so no check gets $5,000 and a Ram it did not ask for. Live: Roblox's answer grants.
Shop.STUDIO_STARTER_FROM_ROBLOX = false

-- The once-a-session Starter Pack offer waits for the prompt guard to clear (fight, carry, alert, a prompt).
Shop.OFFER_WAIT_S = 120
Shop.OFFER_POLL_S = 1

-- A prompt counts as open until its Finished event, the player leaving, or this many seconds (M2-02 S3).
Shop.PROMPT_TIMEOUT_S = 120

-- A pass bought now: PromptGamePassPurchaseFinished(true) is a hint; owned only once UserOwnsGamePassAsync says so
-- (M2-02 M4): tries, seconds apart (about 10 s).
Shop.VERIFY_TRIES = 3
Shop.VERIFY_GAP_S = 3.5
-- A pass check that failed on join is unknown, not "not owned": asked again this many times, the gap doubling from
-- this many seconds (10, 20, 40), and again whenever the shop opens (M2-27 SF3).
Shop.PASS_RETRY_TRIES = 3
Shop.PASS_RETRY_GAP_S = 10

return Shop
