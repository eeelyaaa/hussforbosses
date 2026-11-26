--!nonstrict
-- Moves/_geo: the pivot layout of each boss in fractions of its tier height H, from assets-src/models/<id>.groups.json
-- ("pivot_studs_roblox_offset_from_model_pivot" divided by the tier height in Skins Models heightStuds). Structure, not
-- skin. Needed only where one group rides another on flat joints (Moves/_lib.lua `expand`): TailB on TailA, and Head
-- and the fists on Upper. `lie` is how far up the Body must sit (fraction of H) when it flops 85 degrees onto its
-- back so no part of the mesh goes under the pad (the extreme corner of the group bounding boxes, plus 0.01).
-- `back` is how far behind the feet any group reaches (fraction of H): the hit that tilts the body 12 degrees back lifts it
-- by back x sin 12 so the rear of the mesh does not go under the pad.
-- `guard` is the tail's guard pose, degrees about x (or z when tailAxis = 3) for TailA and TailB (the overlays are authored from it).
-- A creature with no entry uses its body type's reference (the first boss of the type); the other creatures of a
-- type add an entry when they are modelled (M3).
local Geo = {}

Geo.creatures = {
	z2_t2 = { -- Snap Scorpion, H 5.3 (tier 2)
		Head = { 0, 0.3585, -0.0358 }, FistL = { -0.1792, 0.3226, -0.0358 }, FistR = { 0.1792, 0.3226, -0.0358 },
		TailA = { 0, 0.3943, 0.2868 }, TailB = { 0, 0.717, 0.4481 }, lie = 0.518, back = 0.538,
		guard = { A = { 8, 0, 0 }, B = { 6, 0, 0 } },
	},
	z3_t3 = { -- Bit Shark, H 6.8 (tier 3)
		Upper = { 0, 0.2912, 0 }, Head = { 0, 0.5824, -0.0647 }, FistL = { -0.1941, 0.55, -0.0647 },
		FistR = { 0.1941, 0.55, -0.0647 }, lie = 0.61, back = 0.582,
	},
	z4_t4 = { -- Frost Byte, H 8.3 (tier 4)
		Head = { 0, 0.6578, -0.0313 }, FistL = { -0.3133, 0.5952, 0 }, FistR = { 0.3133, 0.5952, 0 }, lie = 0.175, back = 0.188,
	},
	z5_t5 = { -- Ember Drake, H 10.9 (tier 5); the tail runs round the right side (+x) and lies low: it lifts about z
		Head = { 0, 0.6679, -0.0514 }, FistL = { -0.2055, 0.5908, -0.0257 }, FistR = { 0.2055, 0.5908, -0.0257 },
		TailA = { 0, 0.2826, 0.1284 }, TailB = { 0.3339, 0.1079, 0.2569 }, lie = 0.364, back = 0.36,
		tailAxis = 3, flop = { 0, 0 }, guard = { A = { 0, 0, 8 }, B = { 0, 0, 6 } },
	},
	z6_t6 = { -- Star Golem, H 14 (tier 6); Sig is the halo, centre (0, 1.1143, 0)
		Head = { 0, 0.7143, 0 }, FistL = { -0.3429, 0.6, 0 }, FistR = { 0.3429, 0.6, 0 }, Sig = { 0, 1.1143, 0 }, lie = 0.181, back = 0.257,
	},
}

Geo.types = { [1] = "z4_t4", [3] = "z2_t2", [5] = "z3_t3" }

function Geo.of(creatureId: string?, bodyType: number?)
	local g = creatureId and Geo.creatures[creatureId]
	if g then
		return g
	end
	local ref = bodyType and Geo.types[bodyType]
	return ref and Geo.creatures[ref] or nil
end

return Geo
