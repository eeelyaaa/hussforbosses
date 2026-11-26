--!strict
-- Config.Upgrades: boss upgrades (brief system 9). Owned by M2-11 (m2-contract.md section A).
--   Income at level L = base x (1 + 0.25 x (L - 1))   (Config.Income.LEVEL_MULT)
--   Cost from L to L + 1 = 30 x base x 1.3 ^ (L - 1), rounded to whole cash; cap 20.
-- Tests override at runtime; never edit this file for a test.
local Upgrades = {}

Upgrades.COST_MULT = 30
Upgrades.COST_GROWTH = 1.3
Upgrades.LEVEL_CAP = 20

-- Cash to go from `level` to level + 1 for a boss whose level-1 income is `base`; nil at the cap.
function Upgrades.COST(base: number, level: number): number?
	if level >= Upgrades.LEVEL_CAP then
		return nil
	end
	return math.floor(Upgrades.COST_MULT * base * Upgrades.COST_GROWTH ^ (level - 1) + 0.5)
end

return Upgrades
