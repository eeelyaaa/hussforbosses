--!nonstrict
-- Moves/sig/z3_t3: Bit Shark's signature, "lunges and bites with its jaw of square teeth" (build plan). The swayer's
-- template with a double bite:
--   attack    0.45 s: the upper body rears back 20 degrees and the head tips up so the jaw opens wide (0 to 0.15, held its
--             last 0.05); the lunge from the base 0.25 H (0.15 to 0.21) with the head snapping DOWN and shut on the impact
--             at 0.21 s (the heart breaks, cubes at the teeth); the jaw re-opens at 0.25 and snaps shut again at 0.29
--             (the second bite, no second heart); held to 0.33, back to guard by 0.45.
--   lastHeart 1.0 s: the same with a 0.2 s wind-up (impact 0.26, second bite 0.34), then the 0.35 s gloat: rears up, the
--             fins pump twice.
-- The head is never scaled (style guide), so the bite is the head's own turn, 28 degrees past the lunge.
local Swayer = require(script.Parent.Parent.swayer)
local Geo = require(script.Parent.Parent._geo)
local Lib = require(script.Parent.Parent._lib)

local geo = Geo.creatures.z3_t3

local attackKeys = Swayer.strike(geo, 0.15, 0.45, { bite = true })
local attack = { length = 0.45, impactAt = 0.21, impact2At = 0.29, keys = attackKeys }

local lastKeys = Swayer.strike(geo, 0.2, 0.65, { bite = true })
for _, k in ipairs(Swayer.gloat(geo, 0.65)) do
	table.insert(lastKeys, k)
end
local lastHeart = { length = 1.0, impactAt = 0.26, impact2At = 0.34, keys = Lib.sorted(lastKeys) }

return { attack = attack, lastHeart = lastHeart }
