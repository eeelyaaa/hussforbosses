--!nonstrict
-- Moves/sig/z2_t2: Snap Scorpion's signature, "stings with its tail over its head, then a pincer punch" (the manager's
-- example; build plan; style guide section 5, frame by frame):
--   attack    0.45 s: 0.00 to 0.15 the body dips and leans back, both tail segments cock back (TailA 55, TailB 40: the
--             stinger goes up and behind), the claws open; 0.15 to 0.21 the tail whips over the body (TailA -42, TailB 34:
--             the red stinger lands in front of the head at chest height, about 2 to 3 studs ahead of the face on the 5.3 stud
--             boss); impact at 0.21 s (heart breaks, star at the stinger), TailB at 1.2 with a small stab (10 degrees more
--             at 0.24) held to 0.27; 0.27 to 0.33 the right claw punches out 0.25 H and pops to 1.2 (second beat, 0.33);
--             0.33 to 0.45 claw and tail back to guard.
--   lastHeart 1.0 s: the same with a 0.2 s wind-up (impact 0.26, claw 0.38), then the 0.35 s gloat, the tail raised high.
-- Tail angles are about x from each group's own pivot (Geo z2_t2); +x cocks the tail back, -x brings it forward.
local Tailed = require(script.Parent.Parent.tailed)
local Geo = require(script.Parent.Parent._geo)
local Lib = require(script.Parent.Parent._lib)

local geo = Geo.creatures.z2_t2
local OPTS = { windA = { 55, 0, 0 }, windB = { 40, 0, 0 }, hitA = { -42, 0, 0 }, hitB = { 34, 0, 0 }, stab = 10 }

local attack = { length = 0.45, impactAt = 0.21, impact2At = 0.33, keys = Tailed.strike(geo, 0.15, 0.45, OPTS) }

local lastKeys = Tailed.strike(geo, 0.2, 0.65, OPTS)
for _, k in ipairs(Tailed.gloat(geo, 0.65)) do
	table.insert(lastKeys, k)
end
local lastHeart = { length = 1.0, impactAt = 0.26, impact2At = 0.38, keys = Lib.sorted(lastKeys) }

return { attack = attack, lastHeart = lastHeart }
