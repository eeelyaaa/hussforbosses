--!strict
-- Config.Income: income per placed boss (brief systems 8, 9 and 12; m2-contract.md C, D).
-- Income per second = Config.Zones.INCOME[creatureId] x LEVEL_MULT(level) x REBIRTH_MULT(rebirths) x (2 with 2x Cash).
local Income = {}

Income.DEFAULT_LEVEL = 1
Income.LEVEL_CAP = 20 -- brief system 9
Income.CASH_PASS = "pass_2x_cash"
Income.CASH_PASS_MULT = 2

function Income.LEVEL_MULT(level: number): number
	return 1 + 0.25 * (level - 1)
end

-- Boss income x(1 + 0.5 x rebirths) (brief system 12). Config.Rebirth.INCOME_MULT (M2-14) wins when it sets one.
function Income.REBIRTH_MULT(rebirths: number): number
	return 1 + 0.5 * rebirths
end

return Income
