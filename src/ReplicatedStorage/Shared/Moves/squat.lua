--!nonstrict
-- Moves/squat: body type 2, the squat stomper (m1-contract.md H; style guide section 5). Guard pose, idle, the three
-- hit sizes, the attack template (a creature's signature replaces it), lastHeart, gloat, defeat, halfIdle,
-- carryRock. Sig (a jaw, shell, cannon, tusks) shares the Head's hinge on this body type, so it follows the Head.
-- Sizes are fractions of H; -z is forward; +x on r leans or tips back.
local S = {}

local function rest()
	return { p = { 0, 0, 0 }, r = { 0, 0, 0 }, s = 1 }
end

-- Head and Sig turn together about the one hinge.
local function face(r, p)
	return { Head = { r = r, p = p }, Sig = { r = r, p = p } }
end

-- Bob: n cycles of length 1.2 s, Sine, body up by amp H, the head going the other way. Keys appended to `keys`.
local function bob(keys, amp, cycles)
	for c = 0, cycles - 1 do
		local t = c * 1.2
		table.insert(keys, { t = t + 0.6, ease = "Sine", pose = { Body = { p = { 0, amp, 0 } }, Head = { p = { 0, -amp * 0.5, 0 } }, Sig = { p = { 0, -amp * 0.5, 0 } } } })
		table.insert(keys, { t = t + 1.2, ease = "Sine", pose = { Body = rest(), Head = rest(), Sig = rest() } })
	end
end

-- One fist jab: out 0.08 H in 0.05 s, back in 0.08 s. A rest key at t0 holds the fist until it starts.
local function jab(keys, group, t0)
	table.insert(keys, { t = t0, ease = "Quad", pose = { [group] = rest() } })
	table.insert(keys, { t = t0 + 0.05, ease = "Quad", pose = { [group] = { p = { 0, 0, -0.08 } } } })
	table.insert(keys, { t = t0 + 0.13, ease = "Quad", pose = { [group] = rest() } })
end

-- The three-jab triplet at the manager's rhythm: left, right, left, 0.21 s then 0.19 s apart.
local function triplet(keys, t0)
	jab(keys, "FistL", t0)
	jab(keys, "FistR", t0 + 0.21)
	jab(keys, "FistL", t0 + 0.40)
end

local function sorted(keys)
	table.sort(keys, function(a, b)
		return a.t < b.t
	end)
	return keys
end

-- Guard: low and wide, fists out to the sides, a small 0.02 H hop that lands as each ring lands (the loop is 1.0 s
-- and Fight starts it at the ring; the ring itself is never read here).
S.guard = {
	length = 1.0,
	loop = true,
	blendIn = 0.12,
	keys = {
		{ t = 0, ease = "Sine", pose = {
			Body = { s = { 1.05, 0.95, 1.05 } },
			FistL = { p = { -0.05, 0.02, 0 } },
			FistR = { p = { 0.05, 0.02, 0 } },
		} },
		{ t = 0.5, ease = "Sine", pose = { Body = { p = { 0, 0.02, 0 }, s = { 1.05, 0.95, 1.05 } } } },
		{ t = 1.0, ease = "Sine", pose = { Body = { p = { 0, 0, 0 }, s = { 1.05, 0.95, 1.05 } } } },
	},
}

-- Idle on a boss pad: bob 0.03 H on 1.2 s, a jab triplet every 3 s (brief: every 2.5 to 4 s; each boss starts at a
-- random phase so a row never moves in step). Loop = 6 bob cycles.
do
	local keys = {}
	bob(keys, 0.03, 6)
	triplet(keys, 1.5)
	triplet(keys, 4.5)
	S.idle = { length = 7.2, loop = true, keys = sorted(keys) }
end

-- Half idle (placed on a spot): bob 0.015 H, one triplet per loop (7.2 s; brief: every 6 to 8 s).
do
	local keys = {}
	bob(keys, 0.015, 6)
	triplet(keys, 3.0)
	S.halfIdle = { length = 7.2, loop = true, keys = sorted(keys) }
end

-- Carry rock: leans back 8 degrees and rocks 4 degrees each way. The loop is one stride of 1.0 s; the Carry
-- controller sets the speed to the run (opts.speed). Nothing else moves.
S.carryRock = {
	length = 1.0,
	loop = true,
	keys = {
		{ t = 0.25, ease = "Sine", pose = { Body = { r = { 8, 0, 4 } } } },
		{ t = 0.5, ease = "Sine", pose = { Body = { r = { 8, 0, 0 } } } },
		{ t = 0.75, ease = "Sine", pose = { Body = { r = { 8, 0, -4 } } } },
		{ t = 1.0, ease = "Sine", pose = { Body = { r = { 8, 0, 0 } } } },
	},
}

-- Hit reactions. The impact is frame 1: the flash and the beat's effects land at 0. Snap in 0.05 s (Quad), recover
-- with Back. Good: head 15, body 0.9 tall and 1.1 wide. Perfect: twice as far (head 30, 0.85 and 1.15, back 0.1 H).
S.hitGood = {
	length = 0.15,
	flashAt = 0,
	impactAt = 0,
	keys = sorted({
		{ t = 0, ease = "Quad", pose = { Body = rest(), Head = rest(), Sig = rest() } },
		{ t = 0.05, ease = "Quad", pose = {
			Body = { s = { 1.1, 0.9, 1.1 } },
			Head = { r = { 15, 0, 0 } },
			Sig = { r = { 15, 0, 0 } },
		} },
		{ t = 0.15, ease = "Back", pose = { Body = rest(), Head = rest(), Sig = rest() } },
	}),
}
S.hitPerfect = {
	length = 0.2,
	flashAt = 0,
	impactAt = 0,
	keys = sorted({
		{ t = 0, ease = "Quad", pose = { Body = rest(), Head = rest(), Sig = rest() } },
		{ t = 0.05, ease = "Quad", pose = {
			Body = { p = { 0, 0, 0.1 }, s = { 1.15, 0.85, 1.15 } },
			Head = { r = { 30, 0, 0 } },
			Sig = { r = { 30, 0, 0 } },
		} },
		{ t = 0.2, ease = "Back", pose = { Body = rest(), Head = rest(), Sig = rest() } },
	}),
}
-- Big huss: knocked back a full step (0.2 H) in 0.06 s, tilts 12 back then 6 forward, fists below the waist for
-- 0.1 s, then up to guard. A Perfect big huss goes a quarter further (perfectScale).
S.hitBig = {
	length = 0.3,
	flashAt = 0,
	impactAt = 0,
	perfectScale = 1.25,
	keys = sorted({
		{ t = 0, ease = "Quad", pose = { Body = rest(), FistL = rest(), FistR = rest(), Head = rest(), Sig = rest() } },
		{ t = 0.06, ease = "Quad", pose = {
			Body = { p = { 0, 0, 0.2 }, r = { 12, 0, 0 }, s = { 1.1, 0.9, 1.1 } },
			FistL = { p = { 0, -0.2, 0 } },
			FistR = { p = { 0, -0.2, 0 } },
			Head = { r = { 20, 0, 0 } },
			Sig = { r = { 20, 0, 0 } },
		} },
		{ t = 0.15, ease = "Quad", pose = { Body = { p = { 0, 0, 0.2 }, r = { -6, 0, 0 }, s = 1 }, Head = rest(), Sig = rest() } },
		{ t = 0.16, ease = "Quad", pose = { FistL = { p = { 0, -0.2, 0 } }, FistR = { p = { 0, -0.2, 0 } } } },
		{ t = 0.3, ease = "Back", pose = { Body = rest(), FistL = rest(), FistR = rest() } },
	}),
}

-- Gloat keys starting at t0, 0.35 s: fists pumped up twice, a small hop each. Used by `gloat` and inside lastHeart.
function S._gloat(t0)
	local up = { p = { 0, 0.3, 0 } }
	local hop = { p = { 0, 0.03, 0 } }
	return {
		{ t = t0, ease = "Quad", pose = { FistL = rest(), FistR = rest(), Body = rest() } },
		{ t = t0 + 0.05, ease = "Quad", pose = { FistL = up, FistR = up, Body = hop } },
		{ t = t0 + 0.11, ease = "Quad", pose = { FistL = rest(), FistR = rest(), Body = rest() } },
		{ t = t0 + 0.17, ease = "Quad", pose = { FistL = up, FistR = up, Body = hop } },
		{ t = t0 + 0.23, ease = "Quad", pose = { FistL = rest(), FistR = rest(), Body = rest() } },
		{ t = t0 + 0.35, ease = "Back", pose = { FistL = rest(), FistR = rest(), Body = rest() } },
	}
end
S.gloat = { length = 0.35, keys = S._gloat(0) }

-- The attack template: the squat stomper's strike when a creature has no signature of its own. Wind-up 0.15 s
-- (squashes to 0.88 tall and leans back, held its last 0.05), strike 0.06 s (a hop a step forward, 0.05 H high),
-- impact at 0.21 s held 0.06 s with Sig at 1.2, recover to guard by 0.45 s. `windup` is the seconds of wind-up.
function S._strike(windup)
	local t1 = windup -- strike starts
	local ti = windup + 0.06 -- impact
	local th = ti + 0.06 -- impact held
	local mid = windup + 0.03
	return {
		{ t = 0, ease = "Quad", pose = { Body = rest(), Head = rest(), Sig = rest() } },
		{ t = windup - 0.05, ease = "Quad", pose = {
			Body = { p = { 0, -0.05, 0 }, r = { 6, 0, 0 }, s = { 1.1, 0.88, 1.1 } },
			Head = { r = { 6, 0, 0 } },
			Sig = { r = { 5, 0, 0 } },
		} },
		{ t = t1, ease = "Quad", pose = {
			Body = { p = { 0, -0.05, 0 }, r = { 6, 0, 0 }, s = { 1.1, 0.88, 1.1 } },
			Head = { r = { 6, 0, 0 } },
			Sig = { r = { 5, 0, 0 } },
		} },
		{ t = mid, ease = "Quad", pose = { Body = { p = { 0, 0.05, -0.1 }, r = { -2, 0, 0 }, s = { 0.98, 1.04, 0.98 } } } },
		{ t = ti, ease = "Back", pose = {
			Body = { p = { 0, 0, -0.2 }, s = { 1.08, 0.92, 1.08 } },
			Head = { r = { -3, 0, 0 } },
		} },
		-- the jaw snaps shut with Quad (a Back overshoot would pass its 1.2 scale limit)
		{ t = ti, ease = "Quad", pose = { Sig = { r = { -25, 0, 0 }, s = 1.2 } } },
		{ t = th, ease = "Quad", pose = {
			Body = { p = { 0, 0, -0.2 }, s = { 1.08, 0.92, 1.08 } },
			Head = { r = { -3, 0, 0 } },
			Sig = { r = { -25, 0, 0 }, s = 1.2 },
		} },
	}
end

S.attack = {
	length = 0.45,
	impactAt = 0.21,
	keys = (function()
		local k = S._strike(0.15)
		table.insert(k, { t = 0.45, ease = "Back", pose = { Body = rest(), Head = rest() } })
		table.insert(k, { t = 0.45, ease = "Quad", pose = { Sig = rest() } })
		return sorted(k)
	end)(),
}

-- lastHeart: the template's strike once more with a 0.2 s wind-up and the jaw at 1.2, then the 0.35 s gloat; 1.0 s.
-- (The avatar goes down on the impact frame; the Fight controller drives that.)
S.lastHeart = {
	length = 1.0,
	impactAt = 0.26,
	keys = (function()
		local k = S._strike(0.2)
		table.insert(k, { t = 0.65, ease = "Back", pose = { Body = rest(), Head = rest() } })
		table.insert(k, { t = 0.65, ease = "Quad", pose = { Sig = rest() } })
		for _, g in ipairs(S._gloat(0.65)) do
			table.insert(k, g)
		end
		return sorted(k)
	end)(),
}

-- Defeat, 0.8 s: wobbles 10 degrees each way twice (0.2 s), fists drop (0.1 s), flops onto its back (0.15 s), flashes
-- white (0.05 s), then hops up onto the player's head (0.3 s, Back). opts.hopTo (a world position) is where the hop
-- lands; the pose after the move holds (final = "hold") for the Carry controller to take over.
S.defeat = {
	length = 0.8,
	final = "hold",
	suppressBase = true,
	flashAt = 0.45,
	hopWindow = { 0.5, 0.8 },
	keys = sorted({
		{ t = 0, ease = "Quad", pose = { Body = rest(), FistL = rest(), FistR = rest() } },
		{ t = 0.05, ease = "Quad", pose = { Body = { r = { 0, 0, 10 } } } },
		{ t = 0.10, ease = "Quad", pose = { Body = { r = { 0, 0, -10 } } } },
		{ t = 0.15, ease = "Quad", pose = { Body = { r = { 0, 0, 10 } } } },
		{ t = 0.20, ease = "Quad", pose = { Body = { r = { 0, 0, -10 } } } },
		{ t = 0.30, ease = "Quad", pose = { Body = rest(), FistL = { p = { 0, -0.25, 0 } }, FistR = { p = { 0, -0.25, 0 } } } },
		{ t = 0.45, ease = "Quad", pose = { Body = { r = { 85, 0, 0 }, p = { 0, 0.05, 0.1 } } } },
		{ t = 0.50, ease = "Quad", pose = { Body = { r = { 85, 0, 0 }, p = { 0, 0.05, 0.1 } } } },
		{ t = 0.65, ease = "Quad", pose = { Body = { r = { 40, 0, 0 }, p = { 0, 0.6, 0 } } } },
		{ t = 0.80, ease = "Back", pose = { Body = rest(), FistL = rest(), FistR = rest() } },
	}),
}

return S
