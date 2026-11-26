--!nonstrict
-- Moves/sig/z5_t5: Ember Drake's signature, "spins and swings its rock-club tail (no flame), then a fist" (build plan;
-- style guide: "turns 90 degrees away (wind-up), swings back so the rock club lands (first beat), then a red fist").
--   attack    0.45 s: the whole body turns away about its feet (Body -75 degrees, the tail cocks the other way), held 0.10 to
--             0.15 so it reads; the spin back 0.15 to 0.21 (Body +45, the tail whipping 24 more): the club comes round the
--             right side and lands in front at about (2.1, -3.4) studs from the feet on the 10.9 stud boss, impact at
--             0.21 s (the heart breaks, cubes at the club), TailB at 1.2, held to 0.27; the body turns back to face the player
--             (+10) as the right fist punches out 0.25 H and pops to 1.2 (second beat, 0.33); back to guard by 0.45.
--   lastHeart 1.0 s: the same with a 0.2 s wind-up (impact 0.26, fist 0.38), then the 0.35 s gloat (tail raised high).
-- No flame at any frame. The tail runs round the right side (+x): its angles here are about y (the swing) and z (the guard lift, 8 and 6).
local Tailed = require(script.Parent.Parent.tailed)
local Geo = require(script.Parent.Parent._geo)
local Lib = require(script.Parent.Parent._lib)

local geo = Geo.creatures.z5_t5
local OPTS = {
	windA = { 0, -18, 8 }, windB = { 0, -10, 6 }, hitA = { 0, 24, 8 }, hitB = { 0, 16, 6 },
	yawWind = -75, yawHit = 45, yawPunch = 10,
}

local attack = { length = 0.45, impactAt = 0.21, impact2At = 0.33, keys = Tailed.strike(geo, 0.15, 0.45, OPTS) }

local lastKeys = Tailed.strike(geo, 0.2, 0.65, OPTS)
for _, k in ipairs(Tailed.gloat(geo, 0.65)) do
	table.insert(lastKeys, k)
end
local lastHeart = { length = 1.0, impactAt = 0.26, impact2At = 0.38, keys = Lib.sorted(lastKeys) }

return { attack = attack, lastHeart = lastHeart }
