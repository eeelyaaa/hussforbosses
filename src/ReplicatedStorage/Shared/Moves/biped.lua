--!nonstrict
-- Moves/biped: body type 1, the biped bruiser (Bop Bunny, Timber Bear, Bloom Stag, Thump Camel, Frost Byte, Glacier
-- Mammoth, Molten Gorilla, Void Mantis, Star Golem). Groups: Body, Head, FistL, FistR (pivot at the shoulder, the arm
-- hangs below it), optional Sig (a detached or extra part: the golem's halo). Nothing rides anything: flat joints are exact.
-- Style guide section 5: guard = upright, fists up at the chin, bouncing; attack = weight back, the striking fist drawn
-- back past the head (wind-up), the body slides a step in and the blow comes down or straight through.
-- A fist turns about its shoulder: +x swings the hanging arm forward and up (60 = fist at the chin, 90 = straight out,
-- 200 = raised behind the head). The guard holds both arms at G, and every overlay is the deviation from it: an
-- absolute arm angle A is written A - G.
local Lib = require(script.Parent._lib)
local rest, K, sorted, merge = Lib.rest, Lib.K, Lib.sorted, Lib.merge
local B = {}

local G = 60
B.GUARD_ARM = G
local function arm(abs)
	return { r = { abs - G, 0, 0 } }
end
local function armRest()
	return { r = { 0, 0, 0 }, p = { 0, 0, 0 }, s = 1 }
end

-- Wind-up and strike of the striking fists (list of group names). windup: 0.15 or 0.2; endT: back at guard.
-- o.hammer: the arm's overhead angle and impact angle (absolute); the keys of the body come from Lib.strikeBody.
function B.strike(windup, endT, fists, o)
	o = o or {}
	local over, hit = o.over or 200, o.hit or 75
	local ti, th = windup + 0.06, windup + 0.12
	local keys = Lib.strikeBody(windup)
	for _, f in ipairs(fists) do
		table.insert(keys, K(0, "Quad", { [f] = rest() }))
		-- lifted 0.1 H and drawn back 0.05 H as well as turned: a fist is a short block on the shoulder
		local raised = { r = { over - G, 0, 0 }, p = { 0, 0.1, 0.05 } }
		table.insert(keys, K(windup - 0.05, "Quad", { [f] = raised }))
		table.insert(keys, K(windup, "Quad", { [f] = raised }))
		table.insert(keys, K(ti, "Quad", { [f] = { r = { hit - G, 0, 0 }, s = 1.2 } }))
		table.insert(keys, K(th, "Quad", { [f] = { r = { hit - G, 0, 0 }, s = 1.2 } }))
		table.insert(keys, K(endT, "Back", { [f] = rest() }))
	end
	table.insert(keys, K(endT, "Back", { Body = rest(), Head = rest() }))
	return keys
end

local function gloatKeys(t0)
	-- fists pumped up twice (the arms swing up 80 more), a small hop each
	local up = { r = { 80, 0, 0 } }
	local hop = { p = { 0, 0.03, 0 } }
	local function k(t, ease, f, body)
		return K(t, ease, { FistL = f, FistR = f, Body = body })
	end
	return {
		k(t0, "Quad", armRest(), rest()),
		k(t0 + 0.05, "Quad", up, hop),
		k(t0 + 0.11, "Quad", armRest(), rest()),
		k(t0 + 0.17, "Quad", up, hop),
		k(t0 + 0.23, "Quad", armRest(), rest()),
		k(t0 + 0.35, "Back", armRest(), rest()),
	}
end
B.gloatKeys = gloatKeys

-- o.orbit: the name of a detached group that circles on the idle (the halo): 360 degrees about y per 6 s in 12 steps.
function B.build(geo, o)
	o = o or {}
	local S = {}
	local lie = (geo and geo.lie) or 0.2
	local lift = ((geo and geo.back) or 0.3) * math.sin(math.rad(12)) -- the 12 degree tilt of the big hit must not sink the rear
	local function orbit(keys)
		if o.orbit then
			for i = 0, 12 do
				table.insert(keys, K(i * 0.5, "Quad", { [o.orbit] = { r = { 0, 30 * i, 0 } } }))
			end
		end
	end

	-- Guard: upright, fists up at the chin, bouncing 0.03 H on each ring (1.0 s).
	S.guard = {
		length = 1.0, loop = true, blendIn = 0.12,
		keys = {
			K(0, "Sine", { Body = rest(), FistL = arm(G), FistR = arm(G) }),
			K(0.5, "Sine", { Body = { p = { 0, 0.03, 0 } }, Head = { p = { 0, -0.015, 0 } } }),
			K(1.0, "Sine", { Body = rest(), Head = rest(), FistL = arm(G), FistR = arm(G) }),
		},
	}
	-- Idle: bob 0.03 H on 1.2 s, a jab triplet every 3 s; 5 cycles = 6.0 s (the halo, when there is one, circles once).
	do
		local keys = {}
		Lib.bob(keys, 0.03, 5)
		Lib.triplet(keys, 1.5)
		Lib.triplet(keys, 4.5)
		orbit(keys)
		S.idle = { length = 6.0, loop = true, keys = sorted(keys) }
	end
	do
		local keys = {}
		Lib.bob(keys, 0.015, 5)
		Lib.triplet(keys, 3.0)
		orbit(keys)
		S.halfIdle = { length = 6.0, loop = true, keys = sorted(keys) }
	end
	S.carryRock = Lib.carryRock()

	local function allRest()
		return { Body = rest(), Head = rest() }
	end
	S.hitGood = {
		length = 0.15, flashAt = 0, impactAt = 0,
		keys = sorted({
			K(0, "Quad", allRest()),
			K(0.05, "Quad", { Body = { s = { 1.1, 0.9, 1.1 } }, Head = { r = { 15, 0, 0 } } }),
			K(0.15, "Back", allRest()),
		}),
	}
	S.hitPerfect = {
		length = 0.2, flashAt = 0, impactAt = 0,
		keys = sorted({
			K(0, "Quad", allRest()),
			K(0.05, "Quad", { Body = { p = { 0, 0, 0.1 }, s = { 1.15, 0.85, 1.15 } }, Head = { r = { 30, 0, 0 } } }),
			K(0.2, "Back", allRest()),
		}),
	}
	S.hitBig = {
		length = 0.3, flashAt = 0, impactAt = 0, perfectScale = 1.25,
		keys = sorted({
			K(0, "Quad", { Body = rest(), FistL = rest(), FistR = rest(), Head = rest() }),
			K(0.06, "Quad", {
				Body = { p = { 0, lift, 0.2 }, r = { 12, 0, 0 }, s = { 1.1, 0.9, 1.1 } },
				FistL = { p = { 0, -0.2, 0 } }, FistR = { p = { 0, -0.2, 0 } }, Head = { r = { 20, 0, 0 } },
			}),
			K(0.15, "Quad", { Body = { p = { 0, 0, 0.2 }, r = { -6, 0, 0 }, s = 1 }, Head = rest() }),
			K(0.16, "Quad", { FistL = { p = { 0, -0.2, 0 } }, FistR = { p = { 0, -0.2, 0 } } }),
			K(0.3, "Back", { Body = rest(), FistL = rest(), FistR = rest() }),
		}),
	}
	S.gloat = { length = 0.35, keys = gloatKeys(0) }

	-- Attack template: the right fist raised behind the head, then down through the target. Impact 0.21 s.
	S.attack = { length = 0.45, impactAt = 0.21, keys = sorted(B.strike(0.15, 0.45, { "FistR" })) }
	do
		local k = B.strike(0.2, 0.65, { "FistR" })
		for _, key in ipairs(gloatKeys(0.65)) do
			table.insert(k, key)
		end
		S.lastHeart = { length = 1.0, impactAt = 0.26, keys = sorted(k) }
	end

	-- Defeat, 0.8 s. The guard is paused for it, so the arms are keyed from the guard's own angle (G) and drop from there.
	S.defeat = {
		length = 0.8, final = "hold", suppressBase = true, flashAt = 0.45, hopWindow = { 0.5, 0.8 },
		keys = sorted({
			K(0, "Quad", { Body = rest(), FistL = { r = { G, 0, 0 } }, FistR = { r = { G, 0, 0 } } }),
			K(0.05, "Quad", { Body = { r = { 0, 0, 10 } } }),
			K(0.10, "Quad", { Body = { r = { 0, 0, -10 } } }),
			K(0.15, "Quad", { Body = { r = { 0, 0, 10 } } }),
			K(0.20, "Quad", { Body = { r = { 0, 0, -10 } } }),
			K(0.30, "Quad", { Body = rest(), FistL = { r = { 0, 0, 0 }, p = { 0, -0.05, 0 } }, FistR = { r = { 0, 0, 0 }, p = { 0, -0.05, 0 } } }),
			K(0.45, "Quad", { Body = { r = { 85, 0, 0 }, p = { 0, lie + 0.02, 0 } } }),
			K(0.50, "Quad", { Body = { r = { 85, 0, 0 }, p = { 0, lie + 0.02, 0 } } }),
			K(0.65, "Quad", { Body = { r = { 40, 0, 0 }, p = { 0, 0.6, 0 } } }),
			K(0.80, "Back", { Body = rest(), FistL = rest(), FistR = rest() }),
		}),
	}
	return S
end

return B
