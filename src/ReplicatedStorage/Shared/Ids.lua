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

return Ids
