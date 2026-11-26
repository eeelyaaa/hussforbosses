--!strict
-- SpinTable: the Lucky Boss Spin's one odds table (brief system 13). The server rolls from it (Systems/Spin) and the
-- Spin screen lists it (M2-20), so what is shown is what is rolled. Same for every zone, never changes, no pass or
-- boost touches it. Ids only: an outcome is a tier; the creature is Ids.creature(zone, tier); names and pictures come
-- from the skin. Owned by M2-18. Weights are whole percents and total 100.
local SpinTable = {}

SpinTable.ODDS = table.freeze({
	table.freeze({ tier = 1, percent = 40 }), -- the zone's Common
	table.freeze({ tier = 2, percent = 28 }), -- Uncommon
	table.freeze({ tier = 3, percent = 17 }), -- Rare
	table.freeze({ tier = 4, percent = 10 }), -- Epic
	table.freeze({ tier = 5, percent = 4 }), -- Legendary
	table.freeze({ tier = 6, percent = 1 }), -- Mythic
})

function SpinTable.total(): number
	local t = 0
	for _, o in ipairs(SpinTable.ODDS) do
		t += o.percent
	end
	return t
end

-- r in [0, 1) -> tier (pure). Every r gives a tier: no spin gives nothing.
function SpinTable.pick(r: number): number
	local x = math.clamp(r, 0, 0.999999999) * SpinTable.total()
	local acc = 0
	for _, o in ipairs(SpinTable.ODDS) do
		acc += o.percent
		if x < acc then
			return o.tier
		end
	end
	return SpinTable.ODDS[#SpinTable.ODDS].tier
end

-- The percent for a tier (the screen's label), or 0.
function SpinTable.percentOf(tier: number): number
	for _, o in ipairs(SpinTable.ODDS) do
		if o.tier == tier then
			return o.percent
		end
	end
	return 0
end

return SpinTable
