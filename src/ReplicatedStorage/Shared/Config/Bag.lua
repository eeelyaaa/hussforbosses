--!strict
-- Config.Bag: the punching bag and Power (brief system 2 and 3; m1-contract.md section E).
local Bag = {}

Bag.DEFAULT_STRENGTH = 1
Bag.DEFAULT_SPEED = 1
Bag.STRENGTH_MAX = 30 -- brief system 2: "Punch Strength: 30 levels"
Bag.SPEED_MAX = 10 -- brief system 2: "Punch Speed: 10 levels"
-- Studs from the BagPad's centre that count as "on the own bag pad" (server test; contract E).
Bag.PAD_RADIUS = 5
Bag.START_POWER = 0

-- Power one Good punch-unit adds at a Strength level (brief system 2).
function Bag.STRENGTH_VALUE(level: number): number
	return 1.35 ^ (level - 1)
end

return Bag
