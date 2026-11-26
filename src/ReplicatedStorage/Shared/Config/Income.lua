--!strict
-- Config.Income: income per placed boss (brief systems 8 and 9; m1-contract.md section E).
-- Income per second = Config.Zones.INCOME[creatureId] x LEVEL_MULT(level) (rebirth and 2x Cash are M2).
local Income = {}

Income.DEFAULT_LEVEL = 1
Income.LEVEL_CAP = 20 -- brief system 9

function Income.LEVEL_MULT(level: number): number
	return 1 + 0.25 * (level - 1)
end

return Income
