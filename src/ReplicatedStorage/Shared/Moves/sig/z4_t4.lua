--!nonstrict
-- Moves/sig/z4_t4: Frost Byte's signature, "pounds its chest, then smashes down with both blue fists" (build plan).
--   attack    0.45 s: the fists meet at the chest (the pound, 0.04 s), then both arms go up behind the head (wind-up held
--             0.10 to 0.15); the body slides a step in as both fists come down through the target, impact at 0.21 s (the
--             heart breaks; the fists at 1.2), held to 0.27, back to guard by 0.45.
--   lastHeart 1.0 s: the same with a 0.2 s wind-up: the chest is pounded twice (0.04 and 0.12), impact 0.26; then the
--             0.35 s gloat (fists pumped up twice).
-- Arm angles are about each shoulder (+x swings the hanging arm forward and up): the guard holds 60 (fist at the chin), the
-- wind-up 200 (raised behind the head), the impact 75; the keys are the deviation from the guard (biped.lua).
local Biped = require(script.Parent.Parent.biped)
local Lib = require(script.Parent.Parent._lib)

local G = Biped.GUARD_ARM
local K, rest = Lib.K, Lib.rest

local function strike(windup, endT)
	local ti, th = windup + 0.06, windup + 0.12
	local keys = Lib.strikeBody(windup)
	for _, f in ipairs({ "FistL", "FistR" }) do
		local inward = f == "FistL" and 0.22 or -0.22
		local pound = { p = { inward, 0.04, 0.1 } }
		table.insert(keys, K(0, "Quad", { [f] = rest() }))
		table.insert(keys, K(0.04, "Quad", { [f] = pound }))
		if windup >= 0.2 then
			table.insert(keys, K(0.08, "Quad", { [f] = rest() }))
			table.insert(keys, K(0.12, "Quad", { [f] = pound }))
		end
		-- the fist is a short ball on the shoulder, so it is also lifted 0.19 H and drawn back 0.04 H to read as past the head
		table.insert(keys, K(windup - 0.05, "Quad", { [f] = { r = { 200 - G, 0, 0 }, p = { 0, 0.19, 0.04 } } }))
		table.insert(keys, K(windup, "Quad", { [f] = { r = { 200 - G, 0, 0 }, p = { 0, 0.19, 0.04 } } }))
		table.insert(keys, K(ti, "Quad", { [f] = { r = { 75 - G, 0, 0 }, s = 1.2 } }))
		table.insert(keys, K(th, "Quad", { [f] = { r = { 75 - G, 0, 0 }, s = 1.2 } }))
		table.insert(keys, K(endT, "Back", { [f] = rest() }))
	end
	table.insert(keys, K(endT, "Back", { Body = rest(), Head = rest() }))
	return Lib.sorted(keys)
end

local attack = { length = 0.45, impactAt = 0.21, windupBeatsAt = { 0.04 }, keys = strike(0.15, 0.45) }

local lastKeys = strike(0.2, 0.65)
for _, k in ipairs(Biped.gloatKeys(0.65)) do
	table.insert(lastKeys, k)
end
local lastHeart = { length = 1.0, impactAt = 0.26, windupBeatsAt = { 0.04, 0.12 }, keys = Lib.sorted(lastKeys) }

return { attack = attack, lastHeart = lastHeart }
