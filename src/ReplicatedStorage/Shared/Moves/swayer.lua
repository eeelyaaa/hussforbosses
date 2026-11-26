--!nonstrict
-- Moves/swayer: body type 5, the rearing swayer (Bit Shark, Dune Cobra, Nebula Ray, Magma Hydra). Groups: Body (the lower
-- body or tail base, pivot at the feet), Upper (pivot where it rears, the hips), Head (neck), FistL, FistR (shoulders).
-- Head and the fists ride Upper: authored locally, made flat by Moves/_lib.lua expand.
-- Style guide section 5: guard = upright on its tail, swaying 6 degrees on a 1.0 s Sine; attack = the upper body rears
-- back 20 degrees (wind-up), then lunges forward from the base 0.25 H, head or jaw first. The head is never scaled, so
-- the jaw's impact is its snap (a turn), not a pop to 1.2.
-- Sizes are fractions of H, degrees about each group's pivot; -z forward; +x on r leans back / tips the front up.
local Lib = require(script.Parent._lib)
local rest, K, sorted, merge = Lib.rest, Lib.K, Lib.sorted, Lib.merge
local W = {}

local NEST = { parent = "Upper", children = { "Head", "FistL", "FistR" } }

-- The upper body's pose: Upper turns ux about x, Head hx more (local), the fists `fp` shifted (p).
local function up(ux, hx, fp)
	return {
		Upper = { r = { ux, 0, 0 } },
		Head = { r = { hx, 0, 0 } },
		FistL = { p = fp or { 0, 0, 0 } },
		FistR = { p = fp or { 0, 0, 0 } },
	}
end
local function upRest()
	return { Upper = rest(), Head = rest(), FistL = rest(), FistR = rest() }
end

-- The strike. windup: 0.15 (0.2 for lastHeart); endT: back at guard. o.bite: the shark's two chomps (jaw wide on the
-- wind-up, snaps shut on the impact, re-opens, snaps again 0.08 s after the first).
function W.strike(geo, windup, endT, o)
	o = o or {}
	local ti, th = windup + 0.06, windup + 0.12
	local headWind = o.bite and 25 or 4
	local headHit = o.bite and -28 or -12
	local keys = {
		K(0, "Quad", merge({ Body = rest() }, upRest())),
		K(windup - 0.05, "Quad", merge({ Body = { p = { 0, -0.02, 0.05 }, s = { 1.05, 0.95, 1.05 } } }, up(20, headWind))),
		K(windup, "Quad", merge({ Body = { p = { 0, -0.02, 0.05 }, s = { 1.05, 0.95, 1.05 } } }, up(20, headWind))),
		K(windup + 0.03, "Quad", { Body = { p = { 0, 0.03, -0.1 }, s = { 0.98, 1.03, 0.98 } } }),
		K(ti, "Back", { Body = { p = { 0, 0, -0.25 }, s = { 1.06, 0.94, 1.06 } } }),
		K(ti, "Quad", up(-15, headHit, { 0, 0, -0.06 })),
		K(th, "Quad", merge({ Body = { p = { 0, 0, -0.25 }, s = { 1.06, 0.94, 1.06 } } }, up(-15, headHit, { 0, 0, -0.06 }))),
	}
	local lastT = th
	if o.bite then
		-- re-open and snap again; the body and upper stay where the lunge left them
		table.insert(keys, K(ti + 0.04, "Quad", up(-15, 6, { 0, 0, -0.06 })))
		table.insert(keys, K(ti + 0.08, "Quad", up(-15, headHit, { 0, 0, -0.06 })))
		table.insert(keys, K(ti + 0.12, "Quad", up(-15, headHit, { 0, 0, -0.06 })))
		lastT = ti + 0.12
	end
	table.insert(keys, K(endT, "Back", merge({ Body = rest() }, upRest())))
	return Lib.expand(sorted(keys), geo, NEST), lastT
end

local function gloatKeys(t0)
	local upP = { p = { 0, 0.3, 0 } }
	local hop = { p = { 0, 0.03, 0 } }
	local function k(t, ease, fp, body, ux)
		local pose = { Body = body, Upper = { r = { ux, 0, 0 } }, Head = { r = { ux * 0.5, 0, 0 } } }
		pose.FistL, pose.FistR = fp, fp
		return K(t, ease, pose)
	end
	-- rears up proud, the fins pump twice
	return {
		k(t0, "Quad", rest(), rest(), 0),
		k(t0 + 0.05, "Quad", upP, hop, 14),
		k(t0 + 0.11, "Quad", rest(), rest(), 10),
		k(t0 + 0.17, "Quad", upP, hop, 14),
		k(t0 + 0.23, "Quad", rest(), rest(), 10),
		k(t0 + 0.35, "Back", rest(), rest(), 0),
	}
end

function W.gloat(geo, t0)
	return Lib.expand(gloatKeys(t0), geo, NEST)
end

function W.build(geo)
	local S = {}
	local lie = geo.lie or 0.3
	local lift = ((geo and geo.back) or 0.3) * math.sin(math.rad(12)) -- the 12 degree tilt of the big hit must not sink the rear
	local function bodyZ(z, p)
		return { Body = { r = { 0, 0, z }, p = p } }
	end
	-- Guard: upright on its tail, swaying 6 degrees about the base on a 1.0 s Sine (+6 -> -6 -> +6), a 0.02 H hop at
	-- each ring, fins up. Fists are local to Body here (nothing rears).
	do
		local fist = { p = { 0, 0.03, -0.04 } }
		S.guard = {
			length = 1.0, loop = true, blendIn = 0.12,
			keys = {
				K(0, "Sine", merge(bodyZ(6, { 0, 0, 0 }), { FistL = fist, FistR = fist })),
				K(0.5, "Sine", merge(bodyZ(-6, { 0, 0.02, 0 }), { FistL = fist, FistR = fist })),
				K(1.0, "Sine", merge(bodyZ(6, { 0, 0, 0 }), { FistL = fist, FistR = fist })),
			},
		}
	end
	-- Idle and half idle: the bob (Body up by amp H, Head the other way) and the sway about the base share Body's keys:
	-- every 0.6 s, Sine; on the even steps the body is level and leaning swayAmp (alternating sides, 2.4 s period), on
	-- the odd steps it is up by amp and upright. 12 steps = 7.2 s and the loop closes.
	local function bobSway(keys, amp, swayAmp)
		for i = 0, 12 do
			local odd = i % 2 == 1
			local lean = (not odd) and ((i % 4 == 0) and swayAmp or -swayAmp) or 0
			table.insert(keys, K(i * 0.6, "Sine", {
				Body = { p = { 0, odd and amp or 0, 0 }, r = { 0, 0, lean } },
				Head = { p = { 0, odd and -amp * 0.5 or 0, 0 } },
			}))
		end
	end
	do
		local keys = {}
		bobSway(keys, 0.03, 4)
		Lib.triplet(keys, 1.5)
		Lib.triplet(keys, 4.5)
		S.idle = { length = 7.2, loop = true, keys = sorted(keys) }
	end
	do
		local keys = {}
		bobSway(keys, 0.015, 2)
		Lib.triplet(keys, 3.0)
		S.halfIdle = { length = 7.2, loop = true, keys = sorted(keys) }
	end
	S.carryRock = Lib.carryRock()

	local function allRest()
		return merge({ Body = rest() }, upRest())
	end
	S.hitGood = {
		length = 0.15, flashAt = 0, impactAt = 0,
		keys = Lib.expand(sorted({
			K(0, "Quad", allRest()),
			K(0.05, "Quad", merge({ Body = { s = { 1.1, 0.9, 1.1 } } }, up(8, 7))),
			K(0.15, "Back", allRest()),
		}), geo, NEST),
	}
	S.hitPerfect = {
		length = 0.2, flashAt = 0, impactAt = 0,
		keys = Lib.expand(sorted({
			K(0, "Quad", allRest()),
			K(0.05, "Quad", merge({ Body = { p = { 0, 0, 0.1 }, s = { 1.15, 0.85, 1.15 } } }, up(16, 14))),
			K(0.2, "Back", allRest()),
		}), geo, NEST),
	}
	S.hitBig = {
		length = 0.3, flashAt = 0, impactAt = 0, perfectScale = 1.25,
		keys = Lib.expand(sorted({
			K(0, "Quad", allRest()),
			K(0.06, "Quad", merge({ Body = { p = { 0, lift, 0.2 }, r = { 12, 0, 0 }, s = { 1.1, 0.9, 1.1 } } }, up(12, 8, { 0, -0.2, 0 }))),
			K(0.15, "Quad", merge({ Body = { p = { 0, 0, 0.2 }, r = { -6, 0, 0 }, s = 1 } }, up(-4, -2, { 0, -0.2, 0 }))),
			K(0.3, "Back", allRest()),
		}), geo, NEST),
	}

	S.gloat = { length = 0.35, keys = Lib.expand(gloatKeys(0), geo, NEST) }

	do
		local k = W.strike(geo, 0.15, 0.45)
		S.attack = { length = 0.45, impactAt = 0.21, keys = k }
	end
	do
		local k = W.strike(geo, 0.2, 0.65)
		for _, key in ipairs(Lib.expand(gloatKeys(0.65), geo, NEST)) do
			table.insert(k, key)
		end
		S.lastHeart = { length = 1.0, impactAt = 0.26, keys = sorted(k) }
	end

	-- Defeat, 0.8 s: wobbles, fins drop, flops onto its back (lifted by `lie`; the upper body curls forward, which is up
	-- once it lies face up) , flashes, hops.
	local drop = { 0, -0.25, 0 }
	S.defeat = {
		length = 0.8, final = "hold", suppressBase = true, flashAt = 0.45, hopWindow = { 0.5, 0.8 },
		keys = Lib.expand(sorted({
			K(0, "Quad", merge({ Body = rest() }, upRest())),
			K(0.05, "Quad", merge({ Body = { r = { 0, 0, 10 } } }, up(0, 0))),
			K(0.10, "Quad", merge({ Body = { r = { 0, 0, -10 } } }, up(0, 0))),
			K(0.15, "Quad", merge({ Body = { r = { 0, 0, 10 } } }, up(0, 0))),
			K(0.20, "Quad", merge({ Body = { r = { 0, 0, -10 } } }, up(0, 0))),
			K(0.30, "Quad", merge({ Body = rest() }, up(10, 6, drop))),
			K(0.45, "Quad", merge({ Body = { r = { 85, 0, 0 }, p = { 0, lie, 0 } } }, up(-12, -6, drop))),
			K(0.50, "Quad", merge({ Body = { r = { 85, 0, 0 }, p = { 0, lie, 0 } } }, up(-12, -6, drop))),
			K(0.65, "Quad", merge({ Body = { r = { 40, 0, 0 }, p = { 0, 0.6, 0 } } }, up(8, 4))),
			K(0.80, "Back", allRest()),
		}), geo, NEST),
	}
	return S
end

return W
