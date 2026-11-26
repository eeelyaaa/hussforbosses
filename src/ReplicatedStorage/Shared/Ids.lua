--!strict
-- Ids: the content the rules refer to, by id only (build plan, "Architecture requirement: the skin is
-- separate from the rules"). Every name a player sees for these ids comes from Skins/<skinId>/Names.
-- Saves store these ids, never a name.
local Ids = {}

Ids.ZONES = { 1, 2, 3, 4, 5, 6 }
Ids.TIERS = { 1, 2, 3, 4, 5, 6 } -- Common .. Mythic (names in the skin)
Ids.HAZARDS = { 1, 2, 3, 4, 5, 6 } -- one per zone, at its entrance
Ids.BAGS = { 1, 2, 3, 4, 5, 6 } -- bag tiers: the look of Strength
Ids.BODY_TYPES = { 1, 2, 3, 4, 5, 6, 7 } -- structure, not skin (style guide section 9); which is which: Shared/Moves at M1

-- Creature ids: one per tier in every zone (brief, team call 1), "z<zone>_t<tier>", 36 in all.
-- z1_t1 is Chomp Frog in the brickbrawl skin. Body type per creature is content data, added with the
-- boss data at M1/M2.
function Ids.creature(zone: number, tier: number): string
	return ("z%d_t%d"):format(zone, tier)
end

Ids.CREATURES = {} :: { string }
for zone = 1, 6 do
	for tier = 1, 6 do
		table.insert(Ids.CREATURES, Ids.creature(zone, tier))
	end
end

-- Product keys (brief, system 13; build plan, "During the build", step 1). The Roblox ids for these come
-- from the manager (team/manager-todo.md) and live in Config.Shop at M2; until then 0 = stand-in, no call.
Ids.PASSES = {
	"pass_auto_punch",
	"pass_perfect_auto_punch",
	"pass_2x_power",
	"pass_2x_cash",
	"pass_fast_carry",
	"pass_long_lock",
	"pass_extra_spots",
	"pass_quick_hands",
	"pass_iron_grip",
	"pass_starter_pack",
}
Ids.PRODUCTS = {
	"product_cash_small",
	"product_cash_medium",
	"product_cash_large",
	"product_cash_huge",
	"product_spin_1",
	"product_spin_3",
	"product_spin_10",
	"product_instant_shield",
	"product_shield_breaker",
}

-- M1-01 (m1-contract.md sections C, D, G): ids the remotes and the skin key on.
Ids.BANDS = { "easy", "fair", "hard", "veryHard", "brutal", "impossible" } -- order of Config.Fight.BANDS
Ids.GRADES = { "perfect", "good", "miss" }
Ids.CONTEXTS = { "bag", "fight" }
Ids.GROUPS = { "Body", "Head", "FistL", "FistR", "Sig" } -- a boss's moving groups (MeshPart names), structure

-- M2-01 (m2-contract.md sections B, C, F, I). Keys stay the M1 snake_case ids above (the skin's Names and the
-- skin scan key on them); the contract's camelCase names are only labels for the same keys.

-- Punch.Report grades from M2 (contract B1, the manager's P3). Ids.GRADES above stays the burst grades M1 code
-- validates with; M2-06 switches Systems/Punch to REPORT_GRADES when it handles 'untimed'.
Ids.REPORT_GRADES = { "perfect", "good", "untimed", "miss" }

-- The bought mark's source (brief systems 7, 12). Set only by Systems/BoughtMark (M2-14).
Ids.BOUGHT_SOURCES = { "spin", "pack" }

-- Pad kinds per zone (brief system 5): one fixed Common pad, three rolling pads.
Ids.PAD_KINDS = { "fixed", "roll" }

-- The 12 funnel events, in the brief's order ("The first session"; contract F). Names are fixed by the brief.
Ids.FUNNEL = {
	"Joined",
	"FirstBagPunch",
	"FirstPerfectLanded",
	"ReachedFirstBossPower",
	"FirstFightStarted",
	"FirstBossBeaten",
	"FirstBossPlaced",
	"FirstCashCollected",
	"FirstBossUpgraded",
	"StarterPackShown",
	"FirstStrengthBought",
	"Zone2BossPlaced",
}

-- Profile.Notice kinds (toasts the server decides; text in Skins/<id>/Names, added by the screens' tasks).
Ids.NOTICES = {
	"notSaving", -- the profile failed to load: a temp profile, nothing is saved (M2-09)
	"saveFailed", -- a save failed and will retry (M2-09)
	"spotsFull", -- carrying into a full base (M2-11)
	"spotsFullOffer", -- crate take-out with every spot full, no alert, pass not owned: the gold Extra Spots line (M2-11)
	"crateDelivered", -- a boss went to the crate (M2-14, M2-18)
	"stealSafe", -- that boss was stolen less than 60 s ago (M2-15)
	"shieldUp", -- a base is shielded (M2-15)
	"bossReturned", -- your boss went back to its spot (M2-15)
	"rebirthNotReady", -- (M2-14)
	"quoteStale", -- cash pack prices refreshed (M2-18)
	"breakerCharged", -- a late Shield Breaker became a stored charge; n = charges (M2-18)
	"promptBusy", -- no purchase prompt right now (fight, carry, alert, another prompt) (M2-18)
}

-- All 19 shop keys; groups the shop rules refer to.
Ids.SHOP_KEYS = {} :: { string }
for _, k in ipairs(Ids.PASSES) do
	table.insert(Ids.SHOP_KEYS, k)
end
for _, k in ipairs(Ids.PRODUCTS) do
	table.insert(Ids.SHOP_KEYS, k)
end
Ids.CASH_PACKS = { "product_cash_small", "product_cash_medium", "product_cash_large", "product_cash_huge" }
Ids.SPIN_PRODUCTS = { "product_spin_1", "product_spin_3", "product_spin_10" }

function Ids.isPass(key: any): boolean
	return typeof(key) == "string" and table.find(Ids.PASSES, key) ~= nil
end
function Ids.isProduct(key: any): boolean
	return typeof(key) == "string" and table.find(Ids.PRODUCTS, key) ~= nil
end

-- "z3_t5" -> 3, 5; nil, nil for anything else (validates a creature id from any source).
function Ids.parseCreature(id: any): (number?, number?)
	if typeof(id) ~= "string" or #id > 8 then
		return nil, nil
	end
	local z, t = string.match(id, "^z(%d)_t(%d)$")
	local zone, tier = tonumber(z), tonumber(t)
	if zone and tier and zone >= 1 and zone <= 6 and tier >= 1 and tier <= 6 then
		return zone, tier
	end
	return nil, nil
end

return Ids
