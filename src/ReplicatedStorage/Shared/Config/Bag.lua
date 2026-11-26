--!strict
-- Config.Bag: the punching bag, Punch Strength and Punch Speed (brief systems 2 and 3; m2-contract.md C "Bag").
-- Owned by M2-10. Tests override at runtime; never edit this file for a test.
local Bag = {}

Bag.DEFAULT_STRENGTH = 1
Bag.DEFAULT_SPEED = 1
Bag.STRENGTH_MAX = 30 -- brief system 2: "Punch Strength: 30 levels"
Bag.SPEED_MAX = 10 -- brief system 2: "Punch Speed: 10 levels"
-- Studs from the BagPad's centre that count as "on the own bag pad" (server test; contract E).
Bag.PAD_RADIUS = 5
-- Bag.BuyStrength / BuySpeed: within this many studs (ground plane) of the own BagPad's centre (contract C).
Bag.PAD_RANGE = 14
Bag.START_POWER = 0

-- Power one Good punch-unit adds at a Strength level (brief system 2).
function Bag.STRENGTH_VALUE(level: number): number
	return 1.35 ^ (level - 1)
end

-- Cost of buying level L (index L; level 1 is free), brief system 2's tables as printed (from level 5:
-- 1,800 x 1.8 ^ (L - 5) rounded to two figures). Totals 9.67B (Strength) and 8.63M (Speed).
Bag.STRENGTH_COST = {
	0, 150, 400, 900, 1800, 3200, 5800, 10000, 19000, 34000,
	61000, 110000, 200000, 360000, 640000, 1.2e6, 2.1e6, 3.7e6, 6.7e6, 12e6,
	22e6, 39e6, 71e6, 130e6, 230e6, 410e6, 740e6, 1.3e9, 2.4e9, 4.3e9,
}
Bag.SPEED_COST = { 0, 100, 400, 1600, 6500, 26000, 100000, 400000, 1.6e6, 6.5e6 }

-- The bag model changes every five Strength levels: six tiers (Ids.BAGS; the look is the skin's, by tier id).
Bag.LEVELS_PER_TIER = 5
function Bag.TIER(strengthLevel: number): number
	return math.clamp(math.ceil(strengthLevel / Bag.LEVELS_PER_TIER), 1, 6)
end

-- The cost of the next level, or nil at the cap.
function Bag.nextStrengthCost(level: number): number?
	return if level < Bag.STRENGTH_MAX then Bag.STRENGTH_COST[level + 1] else nil
end
function Bag.nextSpeedCost(level: number): number?
	return if level < Bag.SPEED_MAX then Bag.SPEED_COST[level + 1] else nil
end

return Bag
