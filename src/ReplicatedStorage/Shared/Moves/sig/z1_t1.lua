--!nonstrict
-- Moves/sig/z1_t1: Chomp Frog's signature, "hops in and chomps, then a fist bop" (plan; style guide section 5).
-- Sig is the jaw and turns about the hinge it shares with Head. Roblox sign: the modeler's "+X" is Blender's; in the
-- game the jaw's front goes DOWN with a negative x (m1-chomp-frog.md, pivots), up to 25 degrees; the other way it
-- stops after about 5 degrees against the lip, so the wind-up only opens it 4.
--   attack    0.45 s: wind-up 0.15 (held last 0.05), hop a step in (0.05 H high) landing on the impact frame at
--             0.21 s with the jaw chomping (heart breaks, held 0.06 s), then the right fist bops out 0.25 H and
--             pops to 1.2 (0.27 to 0.33), everything back to guard by 0.45.
--   lastHeart 1.0 s: the same with a 0.2 s wind-up (impact 0.26), the jaw at 1.2, the bop, then the 0.35 s gloat.
local Squat = require(script.Parent.Parent.squat)

local function rest()
	return { p = { 0, 0, 0 }, r = { 0, 0, 0 }, s = 1 }
end

local function withBop(strikeKeys, endT, tBop)
	local k = strikeKeys
	-- Body and jaw return to guard over the end of the move.
	table.insert(k, { t = endT, ease = "Back", pose = { Body = rest(), Head = rest() } })
	table.insert(k, { t = endT, ease = "Quad", pose = { Sig = rest() } })
	-- Right fist: held until the bop, 0.06 s out to 0.25 H at 1.2, back by the end.
	table.insert(k, { t = tBop - 0.06, ease = "Quad", pose = { FistR = rest() } })
	table.insert(k, { t = tBop, ease = "Quad", pose = { FistR = { p = { 0, 0, -0.25 }, s = 1.2 } } })
	table.insert(k, { t = endT, ease = "Back", pose = { FistR = rest() } })
	table.sort(k, function(a, b)
		return a.t < b.t
	end)
	return k
end

local attack = { length = 0.45, impactAt = 0.21, keys = withBop(Squat._strike(0.15), 0.45, 0.33) }
local lastHeart = { length = 1.0, impactAt = 0.26, keys = withBop(Squat._strike(0.2), 0.65, 0.38) }
for _, g in ipairs(Squat._gloat(0.65)) do
	table.insert(lastHeart.keys, g)
end
table.sort(lastHeart.keys, function(a, b)
	return a.t < b.t
end)

return { attack = attack, lastHeart = lastHeart }
