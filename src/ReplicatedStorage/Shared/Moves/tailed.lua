--!nonstrict
-- Moves/tailed: body type 3, the tailed striker (Snap Scorpion, Prickle Gecko, Flurry Fox, Cinder Newt, Ember Drake,
-- Comet Hound). Groups: Body, Head, FistL, FistR, TailA (pivot at the tail root), TailB (pivot at the joint, holds the
-- stinger, club or tip). TailB rides TailA, Head and the fists ride Body (Moves/_lib.lua expand makes the flat poses).
-- Style guide section 5: guard = body low, tail raised high behind, segments held in an S; attack = body dips, tail
-- segments cock back, then the tail swings over or around the body to land in front, then a fist as the second beat.
-- Sizes are fractions of H, degrees about each group's pivot; -z forward; +x on r tips the front up. The overlays are
-- authored as the deviation from the guard (the guard stays under every overlay), so an attack's tail angles are
-- written absolute here and the guard subtracted in `tl`.
-- A set is built per creature from its pivot layout (Moves/_geo.lua): `T.build(geo)`. `T.strike` is the template the
-- signature files reuse with their own tail angles.
local Lib = require(script.Parent._lib)
local rest, K, sorted, merge = Lib.rest, Lib.K, Lib.sorted, Lib.merge
local T = {}

local NEST = { parent = "TailA", children = { "TailB" } }

-- The axis the tail lifts about: x for a tail that arches up behind (the scorpion), z for one that runs out to the side
-- and lies low (the drake: +z raises it, x would drive it into the pad). `geo.tailAxis` (1 or 3), read when a set is built.
local axis = 1
local function about(a)
	local r = { 0, 0, 0 }
	r[axis] = a
	return r
end
local function dev(a, b, s) -- tail deviation, degrees about the tail's lift axis
	return { TailA = { r = about(a) }, TailB = { r = about(b), s = s } }
end
local function tailRest()
	return { TailA = rest(), TailB = rest() }
end

-- The strike template. windup: seconds (0.15, or 0.2 for lastHeart); endT: when everything is back at guard.
-- o (all optional): windA, windB, hitA, hitB (absolute tail angles {x,y,z}, TailB local to TailA); stab (extra turn of
-- TailB held between the impact and its end, a flick); yawWind, yawHit, yawPunch (Body turn about y, degrees: the
-- drake's spin; yawPunch is where the body has turned back to for the fist).
function T.strike(geo, windup, endT, o)
	o = o or {}
	local gA, gB = geo.guard.A, geo.guard.B
	local windA, windB = o.windA or { 55, 0, 0 }, o.windB or { 40, 0, 0 }
	local hitA, hitB = o.hitA or { -42, 0, 0 }, o.hitB or { 34, 0, 0 }
	local function tl(a, b, s)
		return {
			TailA = { r = { a[1] - gA[1], a[2] - gA[2], a[3] - gA[3] } },
			TailB = { r = { b[1] - gB[1], b[2] - gB[2], b[3] - gB[3] }, s = s },
		}
	end
	local ti, th = windup + 0.06, windup + 0.12
	local tBop = ti + 0.12
	local keys = Lib.strikeBody(windup)
	-- the drake's spin: Body turns about its feet (strikeBody's keys are 0, wind-up start, wind-up hold, mid, impact, hold)
	local yw, yh, yp = o.yawWind, o.yawHit, o.yawPunch
	if yw then
		local yaw = { 0, yw, yw, (yw + yh) / 2, yh, yh }
		for i, k in ipairs(keys) do
			local b = k.pose.Body
			b.r = { 0, yaw[i], 0 } -- no lean while spinning: Angles turns x about the world axis, which would tip a yawed body sideways
		end
	end
	local function add(t, ease, pose)
		table.insert(keys, K(t, ease, pose))
	end
	-- tail
	add(0, "Quad", tailRest())
	add(windup - 0.05, "Quad", tl(windA, windB, 1))
	add(windup, "Quad", tl(windA, windB, 1))
	-- a mid-swing key so the nested tail stays on its arc (the flat blend is a chord between keys)
	local function avg(a, b) return { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 } end
	add(windup + 0.03, "Quad", tl(avg(windA, hitA), avg(windB, hitB), 1.1))
	local hitPose = tl(hitA, hitB, 1.2)
	add(ti, "Back", { TailA = hitPose.TailA })
	add(ti, "Quad", { TailB = hitPose.TailB })
	if o.stab then
		local sb = { hitB[1] + o.stab, hitB[2], hitB[3] }
		add(ti + 0.03, "Quad", tl(hitA, sb, 1.2))
	end
	add(th, "Quad", tl(hitA, hitB, 1.2))
	add(endT, "Back", tailRest())
	-- claws open on the wind-up, closed on the impact; the right claw bops out as the second beat
	add(0, "Quad", { FistL = rest(), FistR = rest() })
	add(windup - 0.05, "Quad", { FistL = { r = { 0, 14, 0 } }, FistR = { r = { 0, -14, 0 } } })
	add(windup, "Quad", { FistL = { r = { 0, 14, 0 } }, FistR = { r = { 0, -14, 0 } } })
	add(ti, "Quad", { FistL = rest(), FistR = rest() })
	add(th, "Quad", { FistR = rest() })
	add(tBop, "Quad", { FistR = { p = { 0, 0, -0.25 }, s = 1.2 } })
	add(endT, "Back", { FistR = rest() })
	-- the body stays where the impact left it until the end (turned back for the fist when it spun)
	if yp then
		add(tBop, "Quad", { Body = { p = { 0, 0, -0.2 }, r = { 0, yp, 0 }, s = { 1.08, 0.92, 1.08 } } })
	end
	add(endT, "Back", { Body = rest(), Head = rest() })
	return Lib.expand(sorted(keys), geo, NEST), tBop
end

local function gloatKeys(t0)
	local up = { p = { 0, 0.3, 0 } }
	local hop = { p = { 0, 0.03, 0 } }
	local function k(t, ease, fp, body, a, b)
		return K(t, ease, merge({ FistL = fp, FistR = fp, Body = body }, dev(a, b, 1)))
	end
	-- the tail goes up high and quivers while the claws pump twice
	return {
		k(t0, "Quad", rest(), rest(), 0, 0),
		k(t0 + 0.05, "Quad", up, hop, 30, 20),
		k(t0 + 0.11, "Quad", rest(), rest(), 36, 14),
		k(t0 + 0.17, "Quad", up, hop, 30, 22),
		k(t0 + 0.23, "Quad", rest(), rest(), 36, 18),
		k(t0 + 0.35, "Back", rest(), rest(), 0, 0),
	}
end

local function swayKeys(keys, amp, length)
	-- the tail sways about y on a 2.4 s period: 0, +amp, 0, -amp ... every 0.6 s; TailB lags the other way
	local i = 0
	while i * 0.6 <= length + 1e-6 do
		local v = ({ 0, amp, 0, -amp })[i % 4 + 1]
		table.insert(keys, K(i * 0.6, "Sine", { TailA = { r = { 0, v, 0 } }, TailB = { r = { 0, -v * 0.6, 0 } } }))
		i += 1
	end
end

-- The gloat's keys starting at t0 (the tail goes up high and quivers while the claws pump twice), flat and ready to append.
function T.gloat(geo, t0)
	axis = geo.tailAxis or 1
	return Lib.expand(gloatKeys(t0), geo, NEST)
end

function T.build(geo)
	axis = geo.tailAxis or 1
	local S = {}
	local gA, gB = geo.guard.A, geo.guard.B
	local lie = geo.lie or 0.3
	local flopA, flopB = (geo.flop and geo.flop[1]) or -30, (geo.flop and geo.flop[2]) or -20 -- the tail flung as it lands on the back
	local lift = ((geo and geo.back) or 0.3) * math.sin(math.rad(12)) -- the 12 degree tilt of the big hit must not sink the rear

	local function gpose(da, db)
		return { TailA = { r = { gA[1] + da, gA[2], gA[3] } }, TailB = { r = { gB[1] + db, gB[2], gB[3] } } }
	end
	-- Guard: body low and wide, claws forward, the tail held raised in an S, a 0.02 H hop that lands as each ring lands.
	do
		local sq = { 1.05, 0.95, 1.05 }
		local fists = { FistL = { p = { 0, 0.02, -0.03 } }, FistR = { p = { 0, 0.02, -0.03 } } }
		local function key(t, hop, da, db)
			return K(t, "Sine", merge(merge({ Body = { p = { 0, hop, 0 }, s = sq } }, fists), gpose(da, db)))
		end
		S.guard = {
			length = 1.0,
			loop = true,
			blendIn = 0.12,
			keys = Lib.expand({ key(0, 0, 0, 0), key(0.5, 0.02, 3, -2), key(1.0, 0, 0, 0) }, geo, NEST),
		}
	end

	do
		local keys = {}
		Lib.bob(keys, 0.03, 6)
		swayKeys(keys, 6, 7.2)
		Lib.triplet(keys, 1.5)
		Lib.triplet(keys, 4.5)
		S.idle = { length = 7.2, loop = true, keys = Lib.expand(sorted(keys), geo, NEST) }
	end
	do
		local keys = {}
		Lib.bob(keys, 0.015, 6)
		swayKeys(keys, 3, 7.2)
		Lib.triplet(keys, 3.0)
		S.halfIdle = { length = 7.2, loop = true, keys = Lib.expand(sorted(keys), geo, NEST) }
	end
	S.carryRock = Lib.carryRock()

	-- Hit reactions: frame 1 is the impact (flash and effects at 0); snap in 0.05 s, recover with Back. The tail flicks.
	local function allRest()
		return merge({ Body = rest(), Head = rest() }, tailRest())
	end
	S.hitGood = {
		length = 0.15, flashAt = 0, impactAt = 0,
		keys = Lib.expand(sorted({
			K(0, "Quad", allRest()),
			K(0.05, "Quad", merge({ Body = { s = { 1.1, 0.9, 1.1 } }, Head = { r = { 15, 0, 0 } } }, dev(10, 8, 1))),
			K(0.15, "Back", allRest()),
		}), geo, NEST),
	}
	S.hitPerfect = {
		length = 0.2, flashAt = 0, impactAt = 0,
		keys = Lib.expand(sorted({
			K(0, "Quad", allRest()),
			K(0.05, "Quad", merge({ Body = { p = { 0, 0, 0.1 }, s = { 1.15, 0.85, 1.15 } }, Head = { r = { 30, 0, 0 } } }, dev(20, 15, 1))),
			K(0.2, "Back", allRest()),
		}), geo, NEST),
	}
	S.hitBig = {
		length = 0.3, flashAt = 0, impactAt = 0, perfectScale = 1.25,
		keys = Lib.expand(sorted({
			K(0, "Quad", merge({ FistL = rest(), FistR = rest() }, allRest())),
			K(0.06, "Quad", merge({
				Body = { p = { 0, lift, 0.2 }, r = { 12, 0, 0 }, s = { 1.1, 0.9, 1.1 } },
				FistL = { p = { 0, -0.1, 0 } }, FistR = { p = { 0, -0.1, 0 } },
				Head = { r = { 20, 0, 0 } },
			}, dev(30, 24, 1))),
			K(0.15, "Quad", merge({ Body = { p = { 0, 0, 0.2 }, r = { -6, 0, 0 }, s = 1 }, Head = rest() }, dev(-8, -6, 1))),
			K(0.16, "Quad", { FistL = { p = { 0, -0.1, 0 } }, FistR = { p = { 0, -0.1, 0 } } }),
			K(0.3, "Back", merge({ FistL = rest(), FistR = rest(), Body = rest() }, tailRest())),
		}), geo, NEST),
	}

	S.gloat = { length = 0.35, keys = Lib.expand(gloatKeys(0), geo, NEST) }

	-- Attack template: the tail sting, then a claw. Impact at 0.21 s (the heart breaks), the second beat at 0.33 s.
	do
		local k = T.strike(geo, 0.15, 0.45)
		S.attack = { length = 0.45, impactAt = 0.21, impact2At = 0.33, keys = k }
	end
	-- lastHeart: the same, wind-up 0.2 s, the striking part at 1.2, then the 0.35 s gloat (tail raised high) = 1.0 s.
	do
		local k = T.strike(geo, 0.2, 0.65)
		local g = Lib.expand(gloatKeys(0.65), geo, NEST)
		for _, key in ipairs(g) do
			table.insert(k, key)
		end
		S.lastHeart = { length = 1.0, impactAt = 0.26, impact2At = 0.38, keys = sorted(k) }
	end

	-- Defeat, 0.8 s: wobbles 10 degrees each way twice, claws drop, the tail droops, flops onto its back (lifted by
	-- `lie` so no mesh goes under the pad), flashes white, then hops up onto the player's head.
	S.defeat = {
		length = 0.8, final = "hold", suppressBase = true, flashAt = 0.45, hopWindow = { 0.5, 0.8 },
		keys = Lib.expand(sorted({
			K(0, "Quad", merge({ Body = rest(), FistL = rest(), FistR = rest() }, tailRest())),
			K(0.05, "Quad", merge({ Body = { r = { 0, 0, 10 } } }, dev(0, 0, 1))),
			K(0.10, "Quad", merge({ Body = { r = { 0, 0, -10 } } }, dev(0, 0, 1))),
			K(0.15, "Quad", merge({ Body = { r = { 0, 0, 10 } } }, dev(0, 0, 1))),
			K(0.20, "Quad", merge({ Body = { r = { 0, 0, -10 } } }, dev(0, 0, 1))),
			K(0.30, "Quad", merge({ Body = rest(), FistL = { p = { 0, -0.25, 0 } }, FistR = { p = { 0, -0.25, 0 } } }, dev(18, 12, 1))),
			K(0.45, "Quad", merge({ Body = { r = { 85, 0, 0 }, p = { 0, lie, 0 } } }, dev(flopA, flopB, 1))),
			K(0.50, "Quad", merge({ Body = { r = { 85, 0, 0 }, p = { 0, lie, 0 } } }, dev(flopA, flopB, 1))),
			K(0.65, "Quad", merge({ Body = { r = { 40, 0, 0 }, p = { 0, 0.6, 0 } } }, dev(-10, -8, 1))),
			K(0.80, "Back", merge({ Body = rest(), FistL = rest(), FistR = rest() }, tailRest())),
		}), geo, NEST),
	}
	return S
end

return T
