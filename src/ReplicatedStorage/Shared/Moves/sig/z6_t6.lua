--!nonstrict
-- Moves/sig/z6_t6: Star Golem's signature, "its halo flashes as it brings down one huge hammer punch" (build plan).
--   attack    0.45 s: on the wind-up the halo pulses (Sig pops to 1.2 at 0.04 and back by 0.15) and spins one turn about its
--             vertical axis while the right fist is raised behind the head (held 0.10 to 0.15); the body slides a step in
--             (0.2 H) and the fist comes down through the target, impact at 0.21 s (the heart breaks), fist at 1.2, held to
--             0.27, back to guard by 0.45. One fist only.
--   lastHeart 1.0 s: the same with a 0.2 s wind-up (impact 0.26), then the 0.35 s gloat (fists pumped up twice).
-- The pulse is a scale pop and a spin (rigid, the style guide's way); a true Neon flash of the halo alone needs BossMoves to
-- flash one group (it flashes the whole boss, 0.05 s): `haloFlashAt` is the time it would fire, ignored today.
-- Also the golem's idle and half idle: the halo circles once per 6 s in 12 steps.
local Biped = require(script.Parent.Parent.biped)
local Geo = require(script.Parent.Parent._geo)
local Lib = require(script.Parent.Parent._lib)

local geo = Geo.creatures.z6_t6
local K, rest = Lib.K, Lib.rest

local function strike(windup, endT)
	local keys = Biped.strike(windup, endT, { "FistR" })
	table.insert(keys, K(0, "Quad", { Sig = rest() }))
	table.insert(keys, K(windup * 0.25, "Quad", { Sig = { s = 1.2, r = { 0, 90, 0 } } }))
	table.insert(keys, K(windup * 0.7, "Quad", { Sig = { s = 1.2, r = { 0, 250, 0 } } }))
	table.insert(keys, K(windup, "Quad", { Sig = { s = 1, r = { 0, 360, 0 } } }))
	table.insert(keys, K(endT, "Quad", { Sig = { s = 1, r = { 0, 360, 0 } } }))
	return keys
end

local attack = { length = 0.45, impactAt = 0.21, haloFlashAt = 0.04, keys = Lib.sorted(strike(0.15, 0.45)) }

local lastKeys = strike(0.2, 0.65)
for _, k in ipairs(Biped.gloatKeys(0.65)) do
	table.insert(lastKeys, k)
end
local lastHeart = { length = 1.0, impactAt = 0.26, haloFlashAt = 0.05, keys = Lib.sorted(lastKeys) }

local base = Biped.build(geo, { orbit = "Sig" })

return { attack = attack, lastHeart = lastHeart, idle = base.idle, halfIdle = base.halfIdle }
